$: << File.expand_path("..", __FILE__)

require 'net/ntlm'
require 'httpclient'
require 'savon'
require 'fetch_in'

# Ruby Exchange Web Services
module Rews
  WSDL = File.expand_path("../../Services.wsdl", __FILE__)
  SCHEMA_MESSAGES = "http://schemas.microsoft.com/exchange/services/2006/messages"
  SCHEMA_TYPES = "http://schemas.microsoft.com/exchange/services/2006/types"
end

require 'rews/util'
require 'rews/restriction'
require 'rews/shape'
require 'rews/sort_order'
require 'rews/view'
require 'rews/folder'
require 'rews/item'

module Rews
  class Client
    attr_reader :client
    attr_accessor :logdev

    # Rews::Client.new('https://exchange.foo.com/EWS/Exchange.asmx', :ntlm, 'DOMAIN\\user', 'password')
    # Rews::Client.new('https://exchange.foo.com/EWS/Exchange.asmx', :basic, 'DOMAIN\\user', 'password')
    def initialize(endpoint, auth_type, user, password)
      @client = Savon::Client.new do
        wsdl.endpoint = endpoint
        wsdl.namespace = SCHEMA_MESSAGES
        
        http.auth.ssl.verify_mode = :none
        http.auth.send(auth_type, user, password)
      end
    end

    # client.distinguished_folder_id('inbox')
    # client.distinguished_folder_id('inbox', 'foo@bar.com') # to get a folder from another mailbox
    def distinguished_folder_id(id, mailbox_email=nil)
      Folder::DistinguishedFolderId.new(client, id, mailbox_email)
    end

    def log
      yield logger if @logdev
    end

    def logger
      return @logger if @logger
      @logger = Logger.new(@logdev) if @logdev
    end
  end
end
