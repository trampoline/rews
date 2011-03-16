module Rews
  module Folder

    # represents a Folder in a mailbox on an Exchange server
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

      # access the +Folder+ +attributes+
      def [](key)
        @attributes[key]
      end

      # keys of the +Folder+ +attributes+
      def keys
        @attributes.keys
      end

      def inspect
        "#<#{self.class} @folder_id=#{@folder_id.inspect}, @attributes=#{@attributes.inspect}>"
      end
    end

    # <tt>find_*</tt> methods on <tt>Folder::BaseFolderId</tt> return a +FindResult+
    class FindResult
      VIEW_ATTRS = [:includes_last_item_in_range,
                    :indexed_paging_offset,
                    :total_items_in_view]

      VIEW_ATTRS.each do |attr|
        attr_reader attr
      end

      # the +result+ of the +find_*+ call
      attr_reader :result

      def initialize(view, &proc)
        VIEW_ATTRS.each do |attr|
          self.instance_variable_set("@#{attr}", view[attr])
        end
        @result = proc.call(view) if proc
      end

      # count of items in the +result+
      def length
        result.length
      end

      # alias for +length+
      def size
        result.size
      end

      # access an element from +result+
      def [](key)
        result[key]
      end

      def inspect
        attrs = VIEW_ATTRS.map{|attr| "@#{attr}=#{self.send(attr)}"}.join(", ")
        "#<#{self.class} #{attrs}, @result=#{@result.inspect}>"
      end
    end

    # Identifies a Folder
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

      # find <tt>Folder::Folder</tt>s within a <tt>Folder::Folder</tt>
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

      # find <tt>Folder::FolderIds</tt>s within a <tt>Folder::FolderIds</tt>
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

      # find <tt>Item::Item</tt>s in a folder
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

      # find <tt>Item::ItemIds</tt>s in a folder
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

      # retrieve a bunch of <tt>Item::Item</tt>s in one API hit.
      # takes a list of <tt>Item::ItemId</tt>s, or a list of <tt>Item::Item</tt>, 
      # or a <tt>Folder::FindResult</tt> and options to specify +Shape::ItemShape+
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
                mid = mid.item_id if mid.is_a?(Item::Item)
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

      # delete a bunch of Items in one API hit.
      # takes a list of <tt>Item::ItemId</tt>s, or a list of <tt>Item::Item</tt>, 
      # or a <tt>Folder::FindResult</tt> and options to specify DeleteType
      def delete_item(message_ids, opts={})
        opts = check_opts(DELETE_ITEM_OPTS, opts)
        message_ids = message_ids.result if message_ids.is_a?(FindResult)

        r = with_error_check(client, :delete_item_response, :response_messages, :delete_item_response_message) do
          client.request(:wsdl, "DeleteItem", :DeleteType=>opts[:delete_type]) do
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

    # identifies a regular (non-distinguished) Folder on an Exchange server
    class VanillaFolderId < BaseFolderId
      # the Id of the Folder
      attr_reader :id

      # +change_key+ identifies a specific version of the Folder
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

    # identifies a DistinguishedFolder in a mailbox on an Exchange server.
    # the <tt>Client.distinguished_folder_id</tt> method returns <tt>DistinguishedFolderId</tt>s
    class DistinguishedFolderId < BaseFolderId
      # the Id of the DistinguishedFolder e.g. <tt>"inbox"</tt>
      attr_reader :id

      # the email address of the mailbox containing the DistinguishedFolder
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
