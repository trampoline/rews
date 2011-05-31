require File.expand_path("../../spec_helper", __FILE__)

module Rews

  describe SetItemField do
    it "should write Update xml" do
      xml = SetItemField.new("message:IsRead", 
                             [:message, 
                              [:is_read, "true"]]).to_xml


      rsxml = Rsxml.to_rsxml(xml, :ns=>{"t"=>"ews_types"}, :style=>:xml)

      rsxml.should == ["t:SetItemField",
                       ["t:FieldURI", {"FieldURI"=>"message:IsRead"}],
                       ["t:Message", ["t:IsRead", "true"]]]
    end
  end

end
