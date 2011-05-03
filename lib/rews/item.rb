module Rews
  module Item
    module_function

    # return a list of Item objects given a hash formed from an Items element
    def read_items(client, items)
      return [] if !items
      items.map do |item_class,items_of_class|
        items_of_class = [items_of_class] if !items_of_class.is_a?(Array)
        items_of_class.map do |item|
          Item.new(client, item_class, item)
        end
      end.flatten
    end

    # return a list of Item objects from a list of GetItemResponseMessages
    def read_get_item_response_messages(client, get_item_response_messages)
      get_item_response_messages = [get_item_response_messages] if !get_item_response_messages.is_a?(Array)
      items = get_item_response_messages.map do |girm|
        read_items(client, girm[:items])
      end.flatten
    end

    # represents an Item from a mailbox on an Exchange server
    class Item
      attr_reader :client
      attr_reader :item_id
      attr_reader :item_class
      attr_reader :attributes
      
      def initialize(client, item_class, attributes)
        @client = client
        @item_id = ItemId.new(client, attributes[:item_id])
        @item_class = item_class
        @attributes = attributes
      end

      def ==(other)
        other.is_a?(Item) &&
          @client == other.client &&
          @item_id == other.item_id &&
          @item_class == other.item_class &&
          @attributes == other.attributes
      end

      # access the Item attributes
      def [](key)
        @attributes[key]
      end
      
      # names of the Item attributes
      def keys
        @attributes.keys
      end

      def inspect
        "#<#{self.class} @item_class=#{@item_class}, @item_id=#{@folder_id.inspect}, @attributes=#{@attributes.inspect}>"
      end
    end

    # identifies an Item
    class ItemId
      include Util

      attr_reader :client

      # the +Id+ of the Item
      attr_reader :id

      # the version of the Item
      attr_reader :change_key
      
      def initialize(client, item_id)
        @client=client
        @id = item_id[:id]
        @change_key=item_id[:change_key]
        raise "no id" if !@id
      end

      def ==(other)
        @client == other.client &&
          @id == other.id &&
          @change_key == other.change_key
      end

      GET_ITEM_OPTS = {
        :item_shape=>Shape::ITEM_SHAPE_OPTS,
        :ignore_change_keys=>nil
      }

      # get the <tt>Item::Item</tt> identified by this <tt>Item::ItemId</tt>
      def get_item(opts={})
        opts = check_opts(GET_ITEM_OPTS, opts)
        r = with_error_check(client, :get_item_response,:response_messages,:get_item_response_message) do
          client.savon_client.request(:wsdl, "GetItem") do
            http.headers["SOAPAction"] = "\"#{SCHEMA_MESSAGES}/GetItem\"" # required by EWS 2007
            soap.namespaces["xmlns:t"]=SCHEMA_TYPES
            
            xml = Builder::XmlMarkup.new
            
            xml << Shape::ItemShape.new(opts[:item_shape]||{}).to_xml
            xml.wsdl :ItemIds do
              xml << self.to_xml(opts[:ignore_change_keys])
            end
            
            soap.body = xml.target!
          end
        end
        ::Rews::Item.read_get_item_response_messages(client, r).first
      end

      DELETE_ITEM_OPTS = {
        :delete_type! =>nil,
        :ignore_change_keys=>false
      }

      # delete the Item from the server
      def delete_item(opts={})
        opts = check_opts(DELETE_ITEM_OPTS, opts)
        r = with_error_check(client, :delete_item_response, :response_messages, :delete_item_response_message) do
          client.savon_client.request(:wsdl, "DeleteItem", :DeleteType=>opts[:delete_type]) do
            http.headers["SOAPAction"] = "\"#{SCHEMA_MESSAGES}/DeleteItem\"" # required by EWS 2007
            soap.namespaces["xmlns:t"]=SCHEMA_TYPES
            
            xml = Builder::XmlMarkup.new
            
            xml.wsdl :ItemIds do
              xml << self.to_xml(opts[:ignore_change_keys])
            end
            
            soap.body = xml.target!
          end
        end
        true
      end

      UPDATE_ITEM_OPTS = {
        :conflict_resolution => "AutoResolve",
        :message_disposition => "SaveOnly",
        :ignore_change_keys=>false,
        :updates => nil,
      }

      def update_item(opts={})
        opts = check_opts(UPDATE_ITEM_OPTS, opts)
        updates = [*opts[:updates]].compact
        raise "no updates!" if updates.empty?
        r = with_error_check(client, :update_item_response, :response_messages, :update_item_response_message) do
          client.savon_client.request(:wsdl, "UpdateItem", 
                                      :ConflictResolution=>opts[:conflict_resolution],
                                      :MessageDisposition=>opts[:message_disposition]) do
            http.headers["SOAPAction"] = "\"#{SCHEMA_MESSAGES}/UpdateItem\"" # required by EWS 2007
            soap.namespaces["xmlns:t"]=SCHEMA_TYPES
            
            xml = Builder::XmlMarkup.new
            
            xml.wsdl :ItemChanges do
              xml.wsdl :ItemChange do
                xml << self.to_xml(opts[:ignore_change_keys])
                xml.wsdl :Updates do
                    updates.each do |update|
                    xml << update.to_xml
                  end
                end
              end
            end
            
            soap.body = xml.target!
          end
        end
        r
      end

      # sets message:isReadReceiptRequested and message:isDeliveryReceiptRequested
      # properties of a message to false
      def suppress_receipts(opts={})
        update_item(:conflict_resolution=>"AlwaysOverwrite",
                    :message_disposition=>"SaveOnly",
                    :updates=>[SetItemField.new("message:IsReadReceiptRequested",
                                                [:message, nil,
                                                 [:is_read_receipt_requested, nil, "false"]]),
                               SetItemField.new("message:IsDeliveryReceiptRequested",
                                                [:message, nil,
                                                 [:is_delivery_receipt_requested, nil, "false"]])])
      end

      def to_xml(ignore_change_key=false)
        xml = Builder::XmlMarkup.new
        attrs = {:Id=>id.to_s}
        attrs[:ChangeKey] = change_key.to_s if change_key && !ignore_change_key
        xml.t :ItemId, attrs
        xml.target!
      end

      def inspect
        "#<#{self.class} @id=#{id}, @change_key=#{change_key}>"
      end
    end
  end
end
