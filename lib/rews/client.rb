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
