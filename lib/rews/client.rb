module Rews
  class Client
    attr_reader :client
    attr_accessor :logdev

    # create a +Client+ to access Exchange Web Services
    # * using NTLM authentication
    #  Rews::Client.new('https://exchange.foo.com/EWS/Exchange.asmx', :ntlm, 'DOMAIN\\user', 'password')
    # * using basic authentication
    #  Rews::Client.new('https://exchange.foo.com/EWS/Exchange.asmx', :basic, 'DOMAIN\\user', 'password')
    def initialize(endpoint, auth_type, user, password)
      @endpoint=endpoint
      @auth_type = auth_type
      @user=user
      @password=password
      @client = Savon::Client.new do
        wsdl.endpoint = endpoint
        wsdl.namespace = SCHEMA_MESSAGES
        
        http.auth.ssl.verify_mode = :none
        http.auth.send(auth_type, user, password)
      end
    end

    def inspect
      "#<#{self.class} @endpoint=#{@endpoint}, @auth_type=#{@auth_type}, @user=#{@user}, @password=#{@password}>"
    end

    # get a <tt>Folder::DistinguishedFolderId</tt> referencing one of the named top-level folders in an Exchange mailbox
    # * get a folder from the default mailbox
    #  client.distinguished_folder_id('inbox')
    # * get a folder from another mailbox
    #  client.distinguished_folder_id('inbox', 'foo@bar.com')
    def distinguished_folder_id(id, mailbox_email=nil)
      Folder::DistinguishedFolderId.new(client, id, mailbox_email)
    end

    # yield a +Logger+ if +logdev+ has been set
    def log
      yield logger if @logdev
    end

    def logger
      return @logger if @logger
      @logger = Logger.new(@logdev) if @logdev
    end
  end
end
