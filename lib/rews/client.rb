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

    # create items, specifying a list of Rsxml expressions, one for each item in the Items list e.g.
    # 
    #  client.create_item(:items=>[[:suppress_read_receipt, [:reference_item_id, {:id=>"abc", :change_key=>"def"}]]])
    def create_item(opts={})
      opts = check_opts(CREATE_ITEM_OPTS, opts)
      
      items = opts[:items].compact if opts[:items]
      raise "no items!" if items.empty?

      attrs = {}
      attrs[:message_disposition] = opts[:message_disposition] if opts[:message_disposition]
      attrs[:send_meeting_invitations] = opts[:send_meeting_invitations] if opts[:send_meeting_invitations]

      r = with_error_check(self, :create_item_response, :response_messages, :create_item_response_message) do
        savon_client.request(:wsdl, "CreateItem", attrs) do
          http.headers["SOAPAction"] = "\"#{SCHEMA_MESSAGES}/CreateItem\"" # required by EWS 2007
          soap.namespaces["xmlns:t"]=SCHEMA_TYPES

          xml = Builder::XmlMarkup.new

          xml.wsdl :Items do
            items.each do |item|
              xml << Util.rsxml_to_xml(item)
            end
          end

          soap.body = xml.target!
        end
      end
      r
    end

    # +iids+ is a list of Items or ItemIds. If +iids+ is a list of Items,
    # and those Items have +IsRead+ or +IsReadReceiptRequested+ properties then
    # no +SuppressReadReceipt+ Item will be created if ( +IsRead+=true or
    # +IsReadReceiptRequested+=false)
    def suppress_read_receipt(iids)
      iids = iids.result if iids.is_a?(Folder::FindResult)

      items = iids.map do |item_or_item_id|
        item_id = item_or_item_id.is_a?(Item::Item) ? item_or_item_id.item_id : item_or_item_id
        srr = [:suppress_read_receipt, [:reference_item_id, {:id=>item_id.id, :change_key=>item_id.change_key}]]
        if item_or_item_id.is_a?(Item::Item)
          attributes = item_or_item_id.attributes
          if (attributes.has_key?(:is_read) && attributes[:is_read]) || 
              (attributes.has_key?(:is_read_receipt_requested) &&
               !attributes[:is_read_receipt_requested])
            next
          else
            srr
          end
        else
          srr
        end
      end.compact
      create_item(:items=>items) if items.length>0
    end

    GET_ITEM_OPTS = {
      :item_shape=>Shape::ITEM_SHAPE_OPTS,
      :ignore_change_keys=>nil
    }

    # retrieve a bunch of <tt>Item::Item</tt>s in one API hit.
    # takes a list of <tt>Item::ItemId</tt>s, or a list of <tt>Item::Item</tt>, 
    # or a <tt>Folder::FindResult</tt> and options to specify +Shape::ItemShape+
    def get_item(message_ids, opts={})
      opts = check_opts(GET_ITEM_OPTS, opts)
      message_ids = message_ids.result if message_ids.is_a?(Folder::FindResult)

      r = with_error_check(self, :get_item_response,:response_messages,:get_item_response_message) do
        self.savon_client.request(:wsdl, "GetItem") do
          http.headers["SOAPAction"] = "\"#{SCHEMA_MESSAGES}/GetItem\"" # required by EWS 2007
          soap.namespaces["xmlns:t"]=SCHEMA_TYPES
          
          xml = Builder::XmlMarkup.new

          xml << Shape::ItemShape.new(opts[:item_shape]||{}).to_xml
          xml.wsdl :ItemIds do
            message_ids.each do |mid|
              mid = mid.item_id if mid.is_a?(Item::Item)
              xml << mid.to_xml(opts[:ignore_change_keys])
            end
          end

          soap.body = xml.target!
        end
      end
      Item.read_get_item_response_messages(self, r)
    end



    UPDATE_ITEM_OPTS = {
      :conflict_resolution => "AutoResolve",
      :message_disposition => "SaveOnly",
      :ignore_change_keys=>false,
      :updates => nil,
    }

    # bulk update a bunch of Items in one API hit
    # takes a list of <tt>Item::ItemId</tt>s, or a list of <tt>Item::Item</tt>,
    # or a <tt>Folder::FindResult</tt> and applies the same set of updates to each of them
    def update_item(message_ids, opts={})
      opts = check_opts(UPDATE_ITEM_OPTS, opts)
      message_ids = message_ids.result if message_ids.is_a?(Folder::FindResult)

      updates = [*opts[:updates]].compact
      raise "no updates!" if updates.empty?
      r = with_error_check(self, :update_item_response, :response_messages, :update_item_response_message) do
        self.savon_client.request(:wsdl, "UpdateItem", 
                                  :ConflictResolution=>opts[:conflict_resolution],
                                  :MessageDisposition=>opts[:message_disposition]) do
          http.headers["SOAPAction"] = "\"#{SCHEMA_MESSAGES}/UpdateItem\"" # required by EWS 2007
          soap.namespaces["xmlns:t"]=SCHEMA_TYPES
          
          xml = Builder::XmlMarkup.new
          
          xml.wsdl :ItemChanges do
            message_ids.each do |mid|
              mid = mid.item_id if mid.is_a?(Item::Item)
              xml.t :ItemChange do
                xml << mid.to_xml(opts[:ignore_change_keys])
                xml.t :Updates do
                  updates.each do |update|
                    xml << update.to_xml
                  end
                end
              end
            end
          end
          
          soap.body = xml.target!
        end
      end
      r
    end

    DELETE_ITEM_OPTS = {
      :delete_type! =>nil,
      :ignore_change_keys=>false
    }

    # delete a bunch of Items in one API hit.
    # takes a list of <tt>Item::ItemId</tt>s, or a list of <tt>Item::Item</tt>, 
    # or a <tt>Folder::FindResult</tt> and options to specify DeleteType
    def delete_item(message_ids, opts={})
      opts = check_opts(DELETE_ITEM_OPTS, opts)
      message_ids = message_ids.result if message_ids.is_a?(Folder::FindResult)

      r = with_error_check(self, :delete_item_response, :response_messages, :delete_item_response_message) do
        self.savon_client.request(:wsdl, "DeleteItem", :DeleteType=>opts[:delete_type]) do
          http.headers["SOAPAction"] = "\"#{SCHEMA_MESSAGES}/DeleteItem\"" # required by EWS 2007
          soap.namespaces["xmlns:t"]=SCHEMA_TYPES
          
          xml = Builder::XmlMarkup.new

          xml.wsdl :ItemIds do
            message_ids.each do |mid|
              mid = mid.item_id if mid.is_a?(Item::Item)
              xml << mid.to_xml(opts[:ignore_change_keys])
            end
          end

          soap.body = xml.target!
        end
      end
      true
    end

    

  end
end
