require 'rubygems' 
require 'bundler/setup' 

require 'logger'
require 'optparse'
require 'yaml'
require 'google/api_client'
require 'google/api_client/client_secrets'

# Configuration that you probably don't have to change
APPLICATION_NAME = 'Propellant'
PLUS_LOGIN_SCOPE = 'https://www.googleapis.com/auth/plus.me,
                https://www.googleapis.com/auth/plus.media.upload,
                https://www.googleapis.com/auth/plus.profiles.read,
                https://www.googleapis.com/auth/plus.stream.read,
                https://www.googleapis.com/auth/plus.stream.write,
                https://www.googleapis.com/auth/plus.circles.read,
                https://www.googleapis.com/auth/plus.circles.write'

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

config = YAML.load_file(options[:config])

Google::APIClient.logger.level = Logger::DEBUG

# Build the global client
$credentials = Google::APIClient::ClientSecrets.load
$authorization = Signet::OAuth2::Client.new(
    :authorization_uri => $credentials.authorization_uri,
    :token_credential_uri => $credentials.token_credential_uri,
    :client_id => $credentials.client_id,
    :client_secret => $credentials.client_secret,
    :redirect_uri => $credentials.redirect_uris.first,
    :scope => PLUS_LOGIN_SCOPE)
$client = Google::APIClient.new(:application_name => APPLICATION_NAME, :application_version => '0.1.0')
plus = $client.discovered_api('plusDomain')
