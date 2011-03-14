module Rews
  class MessageId
    include Util

    attr_reader :client
    attr_reader :id
    attr_reader :change_key
    
    def initialize(client, id, change_key=nil)
      @client=client
      @id=id
      @change_key=change_key
      raise "no id" if !@id
    end

    def get_message
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
          xml << Gyoku.xml(self.to_xml_hash)
        end

        soap.body = xml.target!
      end
      msgs = r.to_hash.fetch_in(:get_item_response,:response_messages,:get_item_response_message,:items,:message)
    end

    def to_xml_hash(ignore_change_key=false)
      if change_key && !ignore_change_key
        {
          "t:ItemId"=>"",
          :attributes! => {
            "t:ItemId" => {
              "Id" => id.to_s,
              "ChangeKey" => change_key.to_s}}}
      else
        {
          "t:ItemId"=>"",
          :attributes! => {
            "t:ItemId" => {
              "Id" => id.to_s}}}
      end
    end

    def inspect
      "#{self.class}(id: #{id}, change_key: #{change_key})"
    end
  end
end
