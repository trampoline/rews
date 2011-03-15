require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Restriction do
    it "should write Restriction xml" do
      xml = Restriction.new([:and,
                             [:<= , "item:DateTimeReceived", DateTime.parse("2011-03-14T17:02:17+00:00")],
                             [:> , "item:DateTimeReceived", DateTime.parse("2010-03-14T17:02:17+00:00")]]).to_xml

      doc = Nokogiri::XML(xml)
      r = doc.children.first
      r.name.should == "Restriction"
      r.children.size.should == 1
      
      join = r.children.first
      join.name.should == "And"
      join.children.size.should == 2

      le = join.children.first
      le.name.should == "IsLessThanOrEqualTo"
      le.children.size.should == 2
      
      furi = le.children.first
      furi.name.should == "FieldURI"
      furi[:FieldURI].should == "item:DateTimeReceived"

      foc = le.children[1]
      foc.name.should == "FieldURIOrConstant"
      foc.children.size.should == 1

      furi2 = foc.children.first
      furi2.name.should == "Constant"
      furi2[:Value].should == DateTime.parse("2011-03-14T17:02:17+00:00").to_s
      

      gt = join.children[1]
      gt.name.should == "IsGreaterThan"
      gt.children.size.should == 2

      furi3 = gt.children.first
      furi3.name.should == "FieldURI"
      furi3[:FieldURI].should == "item:DateTimeReceived"

      foc2 = gt.children[1]
      foc2.name.should == "FieldURIOrConstant"
      foc2.children.size.should == 1

      furi4 = foc2.children.first
      furi4.name.should == "Constant"
      furi4[:Value].should == DateTime.parse("2010-03-14T17:02:17+00:00").to_s
    end
  end
end
