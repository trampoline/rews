$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rews'
require 'spec'
require 'spec/autorun'
require 'rr'
require 'nokogiri'
require 'request_proxy'

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end
