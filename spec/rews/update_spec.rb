require File.expand_path("../../spec_helper", __FILE__)

module Rews

  describe SetItemField do
    it "should write Update xml" do
      xml = SetItemField.new("item:ResponseObjects", 
                             [:item, 
                              [:response_objects, 
                               [:suppress_read_receipt,
                                [:reference_item_id, {:id=>"foofoo123", :change_key=>"blahblah"}]]]]).to_xml
      doc=Nokogiri::XML(xml).children.first
      doc.name.should == "SetItemField"
      doc.children.length.should == 2
      field_uri = doc.children.first
      item = doc.children[1]

      field_uri.name.should == "FieldURI"
      field_uri["FieldURI"].should == "item:ResponseObjects"

      item.name.should == "Item"
      item.children.length.should == 1
      response_objects = item.children.first

      response_objects.name.should == "ResponseObjects"
      response_objects.children.length.should == 1
      suppress_read_receipt = response_objects.children.first

      suppress_read_receipt.name.should == "SuppressReadReceipt"
      suppress_read_receipt.children.length.should == 1
      reference_item_id = suppress_read_receipt.children.first

      reference_item_id.name.should == "ReferenceItemId"
      reference_item_id.children.length.should == 0
      reference_item_id["Id"].should == "foofoo123"
      reference_item_id["ChangeKey"].should == "blahblah"
    end
  end

end
