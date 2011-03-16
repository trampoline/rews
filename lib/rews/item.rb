module Rews
  module Item
    module_function

    # return a list of Item objects given a hash formed from an Items element
    def read_items(client, items)
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

      def [](key)
        @attributes[key]
      end

      def keys
        @attributes.keys
      end

      def inspect
        "#<#{self.class} @item_class=#{@item_class}, @item_id=#{@folder_id.inspect}, @attributes=#{@attributes.inspect}>"
      end
    end

    class ItemId
      include Util

      attr_reader :client
      attr_reader :id
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

      def get_item(opts={})
        opts = check_opts(GET_ITEM_OPTS, opts)
        r = with_error_check(client, :get_item_response,:response_messages,:get_item_response_message) do
          client.request(:wsdl, "GetItem") do
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

      def delete_item(opts={})
        opts = check_opts(DELETE_ITEM_OPTS, opts)
        r = with_error_check(client, :delete_item_response, :response_messages, :delete_item_response_message) do
          client.request(:wsdl, "DeleteItem", :DeleteType=>opts[:delete_type]) do
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
