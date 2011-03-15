require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Item do
    describe Item::Item do
      it "should parse the item_id and attributes frmo the XML hash" do
        client = Object.new

        i = Item::Item.new(client, 'Message', {:item_id=>{:id=>'1234', :change_key=>'abcd'}, :foo=>100})

        i.client.should == client
        i.item_class.should == 'Message'
        i.item_id.should == Item::ItemId.new(client, {:id=>'1234', :change_key=>'abcd'})

        i[:foo].should == 100
      end
    end

    describe Item::ItemId do

      describe "to_xml" do
      end

      describe "get_item" do
      end

      describe "delete_item" do
      end
    end
  end
end
