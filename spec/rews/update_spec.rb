require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Update do
    describe Update::Xml do
      describe "write_item_sexp" do
        def write_item_sexp(sexp)
          builder = Builder::XmlMarkup.new
          Update::Xml.write_item_sexp(builder, sexp)
          xml = builder.target!
          Nokogiri::XML(xml).children.first
        end

        it "should write a bare element to xml" do
          x = write_item_sexp([:item])
          x.name.should == "Item"
          x.attributes.should == {}
        end

        it "should write an element with attributes to xml" do
          x = write_item_sexp([:meep, {:foo=>10, :bar=>"baz"}])
          x.name.should == "Meep"
          x["Foo"].should == "10"
          x["Bar"].should == "baz"
        end

        it "should write a nested element with attributes to xml" do
          x = write_item_sexp([:foo, nil, [:bar, {:a=>10, :b=>"boo"}]])
          x.name.should == "Foo"
          x.attributes.should == {}
          bar = x.children.first
          bar.name.should == "Bar"
          bar["A"].should == "10"
          bar["B"].should == "boo"
        end

        it "should write multiple child elements to xml" do
          x = write_item_sexp([:foo, nil, [:bar, {:a=>10, :b=>"boo"}], [:baz, {:c=>"c", :doo=>"wop"}]])
          x.name.should == "Foo"
          x.attributes.should == {}
          bar = x.children.first
          bar.name.should == "Bar"
          bar["A"].should == "10"
          bar["B"].should == "boo"
          baz = x.children[1]
          baz.name.should == "Baz"
          baz["C"].should == "c"
          baz["Doo"].should == "wop"
        end

        it "should write text content to xml" do
          x = write_item_sexp([:foo, nil, "FooFoo"])
          x.name.should == "Foo"
          x.attributes.should == {}
          x.children.length.should == 1
          x.children.first.to_s.should == "FooFoo"
        end
      end
    end
  end

  describe SetItemField do
    it "should write Update xml" do
      xml = SetItemField.new("item:ResponseObjects", 
                             [:item, nil, 
                              [:response_objects, nil, 
                               [:suppress_read_receipt, nil,
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
