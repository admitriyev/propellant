require 'rubygems' 
require 'bundler/setup' 

require 'logger'
require 'optparse'
require 'yaml'
require 'google/api_client'
require 'google/api_client/client_secrets'

# Configuration that you probably don't have to change
APPLICATION_NAME = 'Propellant'
PLUS_LOGIN_SCOPE = ['https://www.googleapis.com/auth/plus.me','https://www.googleapis.com/auth/plus.stream.write']

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
$authorization = Signet::OAuth2::Client.new(
    :token_credential_uri => $credentials.token_credential_uri,
    :scope => PLUS_LOGIN_SCOPE,
  	:audience => $credentials.token_credential_uri,
	:issuer => config['client_email'],
  	:signing_key => key)

$authorization.fetch_access_token!
plus = $client.discovered_api('plusDomains')
