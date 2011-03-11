module Rews
  class FolderId
    include Util
    
    attr_reader :client

    def initialize(client)
      @client=client
    end

    INDEXED_PAGE_ITEM_VIEW_OPTS = {:max_entries_returned=>nil, :offset=>0, :base_point=>"Beginning"}

    FIND_FOLDER_ID_OPTS = {:indexed_page_item_view=>INDEXED_PAGE_ITEM_VIEW_OPTS}

    def find_folder_ids(opts={})
      opts = check_opts(FIND_FOLDER_ID_OPTS, opts)

      r = client.request(:wsdl, "FindFolder", "Traversal"=>"Shallow") do
        soap.namespaces["xmlns:t"]=SCHEMA_TYPES
        xml = Builder::XmlMarkup.new
        xml.wsdl :FolderShape do
          xml.t :BaseShape, "IdOnly"
        end
        xml.wsdl :ParentFolderIds do
          xml << Gyoku.xml(self.to_xml_hash)
        end
        soap.body = xml.target!
      end

      folders = [*r.to_hash.fetch_in(:find_folder_response, :response_messages, :find_folder_response_message, :root_folder, :folders, :folder)].compact
      if folders
        folders.map do |folder| 
          VanillaFolderId.new(client, folder[:folder_id][:id], folder[:folder_id][:change_key])
        end
      end
    end

    FIND_MESSAGE_IDS_OPTS = {
      :received_before=>nil, 
      :indexed_page_item_view=>INDEXED_PAGE_ITEM_VIEW_OPTS}

    # find message-ids in a folder
    def find_message_ids(opts={})
      opts = check_opts(FIND_MESSAGE_IDS_OPTS, opts)

      r = client.request(:wsdl, "FindItem", "Traversal"=>"Shallow") do
        soap.namespaces["xmlns:t"]=SCHEMA_TYPES
        
        xml = Builder::XmlMarkup.new
        
        xml.wsdl :ItemShape do
          xml.t :BaseShape, "IdOnly"
        end
        if opts[:indexed_page_item_view]
          o = opts[:indexed_page_item_view]
          attrs = {}
          attrs["MaxEntriesReturned"] = o[:max_entries_returned] if o[:max_entries_returned]
          attrs["Offset"] = o[:offset]
          attrs["BasePoint"] = o[:base_point]
          xml.wsdl :IndexedPageItemView, attrs
        end
        xml.wsdl :ParentFolderIds do
          xml << Gyoku.xml(self.to_xml_hash)
        end

        soap.body = xml.target!
      end
      msgs = [*r.to_hash.fetch_in(:find_item_response, :response_messages, :find_item_response_message, :root_folder, :items, :message)].compact
      msgs.map do |msg|
        MessageId.new(client, msg[:item_id][:id], msg[:item_id][:change_key])
      end
    end

    # get a bunch of messages in one api hit
    def get_messages(message_ids)
      r = client.request(:wsdl, "GetItem") do
        soap.namespaces["xmlns:t"]=SCHEMA_TYPES
        
        xml = Builder::XmlMarkup.new
        xml.wsdl :ItemShape do
          xml.t :BaseShape, "Default"
          xml.t :IncludeMimeContent, true
          xml.t :AdditionalProperties do
            xml.t :FieldURI, :FieldURI=>"item:DateTimeReceived"
          end
        end
        xml.wsdl :ItemIds do
          message_ids.each do |mid|
            xml << Gyoku.xml(mid.to_xml_hash)
          end
        end

        soap.body = xml.target!
      end
      msgs = r.to_hash.fetch_in(:get_item_response,:response_messages,:get_item_response_message)
      msgs.map do |msg|
        msg.fetch_in(:items, :message)
      end
    end
  end

  class VanillaFolderId < FolderId
    attr_reader :id
    attr_reader :change_key

    def initialize(client, id, change_key=nil)
      super(client)
      @id=id
      @change_key=change_key
      raise "no id" if !@id
    end

    def to_xml_hash
      if change_key
        {
          "t:FolderId"=>"",
          :attributes! => {
            "t:ItemId" => {
              "Id" => id.to_s,
              "ChangeKey" => change_key.to_s}}}
      else
        {
          "t:FolderId"=>"",
          :attributes! => {
            "t:ItemId" => {
              "Id" => id.to_s}}}
      end
    end

    def inspect
      "#{self.class}(id: #{id}, change_key: #{change_key})"
    end
  end

  class DistinguishedFolderId < FolderId
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
