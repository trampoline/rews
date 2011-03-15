require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe "SortOrder" do
    it "should write a single sort order" do
      xml = SortOrder.new([["item:DateTimeReceived", "Ascending"]]).to_xml

      doc = Nokogiri::XML(xml)
      doc.children.size.should == 1

      so = doc.children.first
      so.name.should == "SortOrder"
      so.children.size.should == 1

      fo = so.children.first
      fo.name.should == "FieldOrder"
      fo[:Order].should == "Ascending"
      fo.children.size.should == 1
      
      furi = fo.children.first
      furi.name.should == "FieldURI"
      furi[:FieldURI].should == "item:DateTimeReceived"
    end

    it "should write multiple sort orders" do
      xml = SortOrder.new([["item:DateTimeReceived", "Ascending"],
                          ["message:InternetMessageId", "Descending"]]).to_xml

      doc = Nokogiri::XML(xml)
      doc.children.size.should == 1
      
      so = doc.children.first
      so.name.should == "SortOrder"
      so.children.size.should == 2

      fo = so.children.first
      fo.name.should == "FieldOrder"
      fo[:Order].should == "Ascending"
      fo.children.size.should == 1

      furi = fo.children.first
      furi.name.should == "FieldURI"
      furi[:FieldURI].should == "item:DateTimeReceived"

      fo2 = so.children.last
      fo2.name.should == "FieldOrder"
      fo2[:Order].should == "Descending"
      fo2.children.size.should == 1

      furi2 = fo2.children.first
      furi2.name.should == "FieldURI"
      furi2[:FieldURI].should == "message:InternetMessageId"

    end
  end
end
