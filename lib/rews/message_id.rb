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

    GET_MESSAGE_OPTS = {
      :item_shape=>Shape::ITEM_SHAPE_OPTS,
      :ignore_change_keys=>nil
    }

    def get_message(opts={})
      r = client.request(:wsdl, "GetItem") do
        soap.namespaces["xmlns:t"]=SCHEMA_TYPES

        xml = Builder::XmlMarkup.new

        xml << Shape::ItemShape.new(opts[:item_shape]||{}).to_xml
        xml.wsdl :ItemIds do
          xml << Gyoku.xml(self.to_xml_hash(opts[:ignore_change_keys]))
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
