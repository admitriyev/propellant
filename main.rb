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

Google::APIClient.logger.level = Logger::DEBUG
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
	$client.authorization = Signet::OAuth2::Client.new(
	    :token_credential_uri => $credentials.token_credential_uri,
	    :scope => PLUS_LOGIN_SCOPE,
	  	:audience => $credentials.token_credential_uri,
		:issuer => config['client_email'],
	  	:signing_key => key
	)
end

$client.authorization.fetch_access_token!
plus = $client.discovered_api('plusDomains')


puts '**** LIST *****'

result = $client.execute(
	:api_method => plus.activities.list, 
	:headers => {'Content-Type' => 'application/json'},
	:parameters => { 'userId' => 'me', 'collection' => 'user'}
)

puts JSON.parse(result.response.body)

puts '**** INSERT *****'

result = $client.execute(
	:api_method => plus.activities.insert, 
	:headers => {'Content-Type' => 'application/json'},
	:parameters => { 'userId' => 'me'},
	:body_object => { 
		'object' => {
		  'originalContent' => 'Happy Monday! #caseofthemondays'
		},
		'access' => {
		  'items' => [{
		      'type' => 'domain'
		  }],
		  # Required, this does the domain restriction
		  'domainRestricted' => true
		}
})

puts JSON.parse(result.response.body)