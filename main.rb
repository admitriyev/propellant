require 'rubygems' 
require 'bundler/setup' 

require 'logger'
require 'optparse'
require 'yaml'
require 'google/api_client'

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

client = Google::APIClient.new(:application_name =>'Propellant', :application_version => '0.1.0')
