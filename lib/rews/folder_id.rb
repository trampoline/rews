module Rews
  class FolderId
    include Util
    
    attr_reader :client

    def initialize(client)
      @client=client
    end

    def find_folder_ids
      r = client.request(:wsdl, "FindFolder", "Traversal"=>"Shallow") do
        soap.namespaces["xmlns:t"]=SCHEMA_TYPES
        soap.body = {
          "wsdl:FolderShape"=>{"t:BaseShape"=>"IdOnly"},
          "wsdl:ParentFolderIds"=>self.to_xml_hash,
          :order! => ["wsdl:FolderShape","wsdl:ParentFolderIds"]
        }
      end
      folders = [*r.to_hash.fetch_in(:find_folder_response, :response_messages, :find_folder_response_message, :root_folder, :folders, :folder)].compact
      if folders
        folders.map do |folder| 
          VanillaFolderId.new(client, folder[:folder_id][:id], folder[:folder_id][:change_key])
        end
      end
    end

    # find message-ids in a folder
    def find_message_ids
      r = client.request(:wsdl, "FindItem", "Traversal"=>"Shallow") do
        soap.namespaces["xmlns:t"]=SCHEMA_TYPES
        soap.body = {
          "wsdl:ItemShape"=>{"t:BaseShape"=>"IdOnly"},
          "wsdl:ParentFolderIds"=>self.to_xml_hash,
          :order! => ["wsdl:ItemShape","wsdl:ParentFolderIds"]
        }
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
        soap.body = {
          "wsdl:ItemShape"=>{
            "t:BaseShape"=>"Default",
            "t:IncludeMimeContent"=>true},
          "wsdl:ItemIds!"=>message_ids.map{|mid| Gyoku.xml(mid.to_xml_hash)}.join,
          :order! => ["wsdl:ItemShape","wsdl:ItemIds!"]
        }
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
