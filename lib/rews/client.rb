module Rews
  class Client
    include Util

    attr_reader :endpoint
    attr_reader :auth_type
    attr_reader :user
    attr_reader :password
    attr_reader :savon_client

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
      @savon_client = Savon::Client.new do
        wsdl.endpoint = endpoint
        wsdl.namespace = SCHEMA_MESSAGES
        
        http.auth.ssl.verify_mode = :none
        http.auth.send(auth_type, user, password)
      end
    end

    def inspect
      "#<#{self.class} @endpoint=#{@endpoint}, @auth_type=#{@auth_type}, @user=#{@user}, @password=#{@password}>"
    end

    # get a <tt>Folder::DistinguishedFolderId</tt> referencing one of the named top-level Folders in an Exchange mailbox
    # * get a folder from the default mailbox
    #  client.distinguished_folder_id('inbox')
    # * get a folder from another mailbox
    #  client.distinguished_folder_id('inbox', 'foo@bar.com')
    def distinguished_folder_id(id, mailbox_email=nil)
      Folder::DistinguishedFolderId.new(self, id, mailbox_email)
    end

    CREATE_ITEM_OPTS={
      :items=>nil,
      :message_disposition=>nil,
      :send_meeting_invitations=>nil
    }

    # create items, specifying a 
    def create_item(opts={})
      opts = check_opts(CREATE_ITEM_OPTS, opts)
      
      items = opts[:items].compact if opts[:items]
      raise "no items!" if items.empty?

      r = with_error_check(self, :create_item_response, :response_messages, :create_item_response_message) do
        savon_client.request(:wsdl, "CreateItem", attrs) do
          http.headers["SOAPAction"] = "\"#{SCHEMA_MESSAGES}/CreateItem\"" # required by EWS 2007
          soap.namespaces["xmlns:t"]=SCHEMA_TYPES

          xml = Builder::XmlMarkup.new

          xml.wsdl :CreateItem do
            xml.t :Items do
              items.each do |item|
                xml << Util.rsxml_to_xml(item)
              end
            end
          end

          soap.body = xml.target!
        end
      end
      r
    end
  end
end
