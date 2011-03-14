module Rews
  module Folder
    class Folder
      attr_reader :client
      attr_reader :folder_id
      attr_reader :attributes

      def initialize(client, folder)
        @folder_id = VanillaFolderId.new(client, folder[:folder_id])
        @attributes = folder
      end

      def [](key)
        @attributes[key]
      end

      def keys
        @attributes.keys
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
    end

    class BaseFolderId
      include Util
      
      attr_reader :client

      def initialize(client)
        @client=client
      end

      FIND_FOLDERS_OPTS = {
        :restriction=>nil,
        :indexed_page_folder_view=>View::INDEXED_PAGE_VIEW_OPTS,
        :folder_shape=>Shape::FOLDER_SHAPE_OPTS}

      def find_folders(opts={})
        opts = check_opts(FIND_FOLDERS_OPTS, opts)

        r = client.request(:wsdl, "FindFolder", "Traversal"=>"Shallow") do
          soap.namespaces["xmlns:t"]=SCHEMA_TYPES
          xml = Builder::XmlMarkup.new

          xml << Shape::FolderShape.new(opts[:folder_shape]||{}).to_xml
          xml << View::IndexedPageFolderView.new(opts[:indexed_page_folder_view]).to_xml if opts[:indexed_page_folder_view]
          xml << Restriction.new(opts[:restriction]).to_xml if opts[:restriction]

          xml.wsdl :ParentFolderIds do
            xml << Gyoku.xml(self.to_xml_hash)
          end
          soap.body = xml.target!
        end

        FindResult.new(r.to_hash.fetch_in(:find_folder_response, :response_messages, :find_folder_response_message, :root_folder)) do |view|
          results = view.fetch_in(:folders, :folder)
          results = [results] if !results.is_a?(Array)
          results.compact.map do |folder|
            Folder.new(client, folder)
          end
        end
      end

      def find_folder_ids(opts={})
        opts = check_opts(FIND_FOLDERS_OPTS, opts)

        shape = opts[:folder_shape] ||={} 
        shape[:base_shape]||=:IdOnly

        find_folders(opts).result.map!(&:folder_id)
      end

      FIND_MESSAGES_OPTS = {
        :restriction=>nil,
        :sort_order=>nil,
        :indexed_page_item_view=>View::INDEXED_PAGE_VIEW_OPTS,
        :item_shape=>Shape::ITEM_SHAPE_OPTS}

      # find message-ids in a folder
      def find_messages(opts={})
        opts = check_opts(FIND_MESSAGES_OPTS, opts)

        r = client.request(:wsdl, "FindItem", "Traversal"=>"Shallow") do
          soap.namespaces["xmlns:t"]=SCHEMA_TYPES
          
          xml = Builder::XmlMarkup.new
          
          xml << Shape::ItemShape.new(opts[:item_shape]||{}).to_xml
          xml << View::IndexedPageItemView.new(opts[:indexed_page_item_view]).to_xml if opts[:indexed_page_item_view]
          xml << Restriction.new(opts[:restriction]).to_xml if opts[:restriction]
          xml << SortOrder.new(opts[:sort_order]).to_xml if opts[:sort_order]

          xml.wsdl :ParentFolderIds do
            xml << Gyoku.xml(self.to_xml_hash)
          end

          soap.body = xml.target!
        end
        
        FindResult.new(r.to_hash.fetch_in(:find_item_response, :response_messages, :find_item_response_message, :root_folder)) do |view|
          results = view.fetch_in(:items, :message)
          results = [results] if !results.is_a?(Array)
          results.compact.map do |msg|
            Message::Message.new(client, msg)
          end
        end
      end

      def find_message_ids(opts={})
        opts = check_opts(FIND_MESSAGES_OPTS, opts)

        shape = opts[:item_shape] ||= {}
        shape[:base_shape]||=:IdOnly

        find_messages(opts).result.map!(&:message_id)
      end

      GET_MESSAGES_OPTS = {
        :item_shape=>Shape::ITEM_SHAPE_OPTS,
        :ignore_change_keys=>nil
      }

      # get a bunch of messages in one api hit
      def get_messages(message_ids, opts={})
        opts = check_opts(GET_MESSAGES_OPTS, opts)

        r = client.request(:wsdl, "GetItem") do
          soap.namespaces["xmlns:t"]=SCHEMA_TYPES
          
          xml = Builder::XmlMarkup.new

          xml << Shape::ItemShape.new(opts[:item_shape]||{}).to_xml
          xml.wsdl :ItemIds do
            message_ids.each do |mid|
              xml << Gyoku.xml(mid.to_xml_hash(opts[:ignore_change_keys]))
            end
          end

          soap.body = xml.target!
        end
        msgs = r.to_hash.fetch_in(:get_item_response,:response_messages,:get_item_response_message)
        msgs = [msgs] if !msgs.is_a?(Array)
        msgs.compact.map do |msg|
          msg.fetch_in(:items, :message)
        end
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

      def to_xml_hash
        if change_key
          {
            "t:FolderId"=>"",
            :attributes! => {
              "t:FolderId" => {
                "Id" => id.to_s,
                "ChangeKey" => change_key.to_s}}}
        else
          {
            "t:FolderId"=>"",
            :attributes! => {
              "t:FolderId" => {
                "Id" => id.to_s}}}
        end
      end

      def inspect
        "#{self.class}(id: #{id}, change_key: #{change_key})"
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

      def to_xml_hash
        {
          "t:DistinguishedFolderId"=>mailbox_xml_hash,
          :attributes! => {"t:DistinguishedFolderId"=>{"Id"=>id}}}
      end

      def inspect
        "#{self.class}(id: #{id}, mailbox_email: #{mailbox_email})"
      end

      private

      def mailbox_xml_hash
        if mailbox_email
          {
            "t:Mailbox"=>{
              "t:EmailAddress"=>mailbox_email}}
        else
          ""
        end
      end
    end
  end
end
