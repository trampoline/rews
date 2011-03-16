module Rews
  module Folder
    class Folder
      attr_reader :client
      attr_reader :folder_id
      attr_reader :attributes

      def initialize(client, folder)
        @client = client
        @folder_id = VanillaFolderId.new(client, folder[:folder_id])
        @attributes = folder
      end

      def ==(other)
        other.is_a?(Folder) &&
          @client == other.client &&
          @folder_id == other.folder_id &&
          @attributes == other.attributes
      end

      def [](key)
        @attributes[key]
      end

      def keys
        @attributes.keys
      end

      def inspect
        "#<#{self.class} @folder_id=#{@folder_id.inspect}, @attributes=#{@attributes.inspect}>"
      end
    end

    class FindResult
      VIEW_ATTRS = [:includes_last_item_in_range,
                    :indexed_paging_offset,
                    :total_items_in_view]

      VIEW_ATTRS.each do |attr|
        attr_reader attr
      end
      attr_reader :result

      def initialize(view, &proc)
        VIEW_ATTRS.each do |attr|
          self.instance_variable_set("@#{attr}", view[attr])
        end
        @result = proc.call(view) if proc
      end

      def length
        result.length
      end

      def size
        result.size
      end

      def [](key)
        result[key]
      end

      def inspect
        attrs = VIEW_ATTRS.map{|attr| "@#{attr}=#{self.send(attr)}"}.join(", ")
        "#<#{self.class} #{attrs}, @result=#{@result.inspect}>"
      end
    end

    class BaseFolderId
      include Util
      
      attr_reader :client

      def initialize(client)
        @client=client
      end

      FIND_FOLDER_OPTS = {
        :restriction=>nil,
        :indexed_page_folder_view=>View::INDEXED_PAGE_VIEW_OPTS,
        :folder_shape=>Shape::FOLDER_SHAPE_OPTS}

      def find_folder(opts={})
        opts = check_opts(FIND_FOLDER_OPTS, opts)

        r = with_error_check(client, :find_folder_response, :response_messages, :find_folder_response_message) do
          client.request(:wsdl, "FindFolder", "Traversal"=>"Shallow") do
            soap.namespaces["xmlns:t"]=SCHEMA_TYPES
            xml = Builder::XmlMarkup.new
            
            xml << Shape::FolderShape.new(opts[:folder_shape]||{}).to_xml
            xml << View::IndexedPageFolderView.new(opts[:indexed_page_folder_view]).to_xml if opts[:indexed_page_folder_view]
            xml << Restriction.new(opts[:restriction]).to_xml if opts[:restriction]
            
            xml.wsdl :ParentFolderIds do
              xml << self.to_xml
            end
            soap.body = xml.target!
          end
        end

        FindResult.new(r.fetch_in(:root_folder)) do |view|
          results = view.fetch_in(:folders, :folder)
          results = [results] if !results.is_a?(Array)
          results.compact.map do |folder|
            Folder.new(client, folder)
          end
        end
      end

      def find_folder_id(opts={})
        opts = check_opts(FIND_FOLDER_OPTS, opts)

        shape = opts[:folder_shape] ||={} 
        shape[:base_shape]||=:IdOnly

        r = find_folder(opts)
        r.result.map!(&:folder_id)
        r
      end

      FIND_ITEM_OPTS = {
        :restriction=>nil,
        :sort_order=>nil,
        :indexed_page_item_view=>View::INDEXED_PAGE_VIEW_OPTS,
        :item_shape=>Shape::ITEM_SHAPE_OPTS}

      # find message-ids in a folder
      def find_item(opts={})
        opts = check_opts(FIND_ITEM_OPTS, opts)

        r = with_error_check(client, :find_item_response, :response_messages, :find_item_response_message) do
          client.request(:wsdl, "FindItem", "Traversal"=>"Shallow") do
            soap.namespaces["xmlns:t"]=SCHEMA_TYPES
            
            xml = Builder::XmlMarkup.new
            
            xml << Shape::ItemShape.new(opts[:item_shape]||{}).to_xml
            xml << View::IndexedPageItemView.new(opts[:indexed_page_item_view]).to_xml if opts[:indexed_page_item_view]
            xml << Restriction.new(opts[:restriction]).to_xml if opts[:restriction]
            xml << SortOrder.new(opts[:sort_order]).to_xml if opts[:sort_order]

            xml.wsdl :ParentFolderIds do
              xml << self.to_xml
            end

            soap.body = xml.target!
          end
        end
        
        FindResult.new(r.to_hash.fetch_in(:root_folder)) do |view|
          results = Item.read_items(client, view[:items])
        end
      end

      def find_item_id(opts={})
        opts = check_opts(FIND_ITEM_OPTS, opts)

        shape = opts[:item_shape] ||= {}
        shape[:base_shape]||=:IdOnly

        r = find_item(opts)
        r.result.map!(&:item_id)
        r
      end

      GET_ITEM_OPTS = {
        :item_shape=>Shape::ITEM_SHAPE_OPTS,
        :ignore_change_keys=>nil
      }

      # get a bunch of messages in one api hit
      def get_item(message_ids, opts={})
        opts = check_opts(GET_ITEM_OPTS, opts)
        message_ids = message_ids.result if message_ids.is_a?(FindResult)

        r = with_error_check(client, :get_item_response,:response_messages,:get_item_response_message) do
          client.request(:wsdl, "GetItem") do
            soap.namespaces["xmlns:t"]=SCHEMA_TYPES
            
            xml = Builder::XmlMarkup.new

            xml << Shape::ItemShape.new(opts[:item_shape]||{}).to_xml
            xml.wsdl :ItemIds do
              message_ids.each do |mid|
                xml << mid.to_xml(opts[:ignore_change_keys])
              end
            end

            soap.body = xml.target!
          end
        end
        Item.read_get_item_response_messages(client, r)
      end

      DELETE_ITEM_OPTS = {
        :delete_type! =>nil,
        :ignore_change_keys=>false
      }

      def delete_item(message_ids, opts={})
        opts = check_opts(DELETE_ITEM_OPTS, opts)
        message_ids = message_ids.result if message_ids.is_a?(FindResult)

        r = with_error_check(client, :delete_item_response, :response_messages, :delete_item_response_message) do
          client.request(:wsdl, "DeleteItem", :DeleteType=>opts[:delete_type]) do
            soap.namespaces["xmlns:t"]=SCHEMA_TYPES
            
            xml = Builder::XmlMarkup.new

            xml.wsdl :ItemIds do
              message_ids.each do |mid|
                xml << mid.to_xml(opts[:ignore_change_keys])
              end
            end

            soap.body = xml.target!
          end
        end
        true
      end
    end

    class VanillaFolderId < BaseFolderId
      attr_reader :id
      attr_reader :change_key

      def initialize(client, folder_id)
        super(client)
        @id=folder_id[:id]
        @change_key=folder_id[:change_key]
        raise "no id" if !@id
      end

      def ==(other)
        other.is_a?(VanillaFolderId) &&
          @client == other.client &&
          @id == other.id &&
          @change_key == other.change_key
      end

      def to_xml
        xml = Builder::XmlMarkup.new
        attrs = {:Id=>id.to_s}
        attrs[:ChangeKey] = change_key.to_s if change_key
        xml.t :FolderId, attrs
        xml.target!
      end

      def inspect
        "#<#{self.class} @id=#{id}, @change_key=#{change_key}>"
      end
    end

    class DistinguishedFolderId < BaseFolderId
      attr_reader :id
      attr_reader :mailbox_email

      def initialize(client, id, mailbox_email=nil)
        super(client)
        @id = id
        @mailbox_email = mailbox_email
        raise "no id" if !@id
      end

      def ==(other)
        other.is_a?(DistinguishedFolderId) &&
          @client = other.client &&
          @id = other.id &&
          @mailbox_email = other.mailbox_email
      end

      def to_xml
        xml = Builder::XmlMarkup.new
        xml.t :DistinguishedFolderId, :Id=>id do
          if mailbox_email
            xml.t :Mailbox do
              xml.t :EmailAddress, mailbox_email
            end
          end
        end
        xml.target!
      end

      def inspect
        "#<#{self.class} @id=#{id}, @mailbox_email=#{mailbox_email}>"
      end
    end
  end
end
