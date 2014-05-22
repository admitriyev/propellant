require 'rubygems' 
require 'bundler/setup' 

require 'logger'
require 'optparse'
require 'yaml'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'

# Configuration that you probably don't have to change
APPLICATION_NAME = 'Propellant'
PLUS_LOGIN_SCOPE = 
	['https://www.googleapis.com/auth/plus.circles.read', 
	'https://www.googleapis.com/auth/plus.circles.write', 
	'https://www.googleapis.com/auth/plus.me', 
	'https://www.googleapis.com/auth/plus.media.upload', 
	'https://www.googleapis.com/auth/plus.stream.read', 
	'https://www.googleapis.com/auth/plus.stream.write']
CREDENTIAL_STORE_FILE = "#{$0}-oauth2.json"

options = {:config => nil}
OptionParser.new do |opts|
  opts.banner = "Usage: main.rb [options]"

  opts.on('-c', '--config config', 'Config file') do |config|
    options[:config] = config
  end

  opts.on('-j', '--json json_file', 'JSON payload in a file') do |json_file|
    options[:json_file] = json_file
  end

  opts.on('-a', '--action action', 'Action: list, list_all, insert, get') do |action|
    options[:action] = action
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end.parse!

if options[:config] == nil
    puts 'Missing arguments. Use -h for help'
    exit
end

config = YAML.load_file(options[:config])['config']

Google::APIClient.logger.level = Logger::INFO #DEBUG
$client = Google::APIClient.new(:application_name => APPLICATION_NAME, :application_version => '0.1.0')

# Load private key
key = Google::APIClient::KeyUtils.load_from_pkcs12(
	config['key_file'],
	config['key_secret'])

# Create a client
$credentials = Google::APIClient::ClientSecrets.load

if config['oauth_type'] == 'user'
	 file_storage = Google::APIClient::FileStorage.new(CREDENTIAL_STORE_FILE)
	 flow = Google::APIClient::InstalledAppFlow.new(
	    :client_id => $credentials.client_id,
	    :client_secret => $credentials.client_secret,
	    :scope => PLUS_LOGIN_SCOPE
	)
	$client.authorization = flow.authorize(file_storage)	 
else
	client_asserter = Google::APIClient::JWTAsserter.new(
		config['client_email'],
	    PLUS_LOGIN_SCOPE,
	  	key
	)
	$client.authorization = client_asserter.authorize(config['user_email'])
end

$client.authorization.fetch_access_token!
plus_api = $client.discovered_api('plus')
plus_domain_api = $client.discovered_api('plusDomains')


#puts 'REQUEST: ' + options[:action].to_s
$result = nil

case options[:action]
when 'list_all'
	$result = $client.execute(
		:api_method => plus_api.activities.list, 
		:headers => {'Content-Type' => 'application/json'},
		:parameters => { 'userId' => 'me', 'collection' => 'public'}
	)
when 'list'
	$result = $client.execute(
		:api_method => plus_domain_api.activities.list, 
		:headers => {'Content-Type' => 'application/json'},
		:parameters => { 'userId' => 'me', 'collection' => 'user'}
	)
when 'insert'
	json_payload = JSON.load(IO.read(options[:json_file]))
	$result = $client.execute(
		:api_method => plus_domain_api.activities.insert, 
		:headers => {'Content-Type' => 'application/json'},
		:parameters => { 'userId' => 'me'},
		:body_object => json_payload
	)
end

puts JSON.pretty_generate( JSON.parse($result.response.body) ) if !$result.nil?
