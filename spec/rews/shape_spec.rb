require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Shape do
    describe Shape::FolderShape do
      it "should write FolderShape xml" do
        xml = Shape::FolderShape.new(:base_shape=>:IdOnly,
                                     :additional_properties=>[[:field_uri, "folder:FolderId"],
                                                              [:field_uri, "folder:TotalCount"]]).to_xml

        doc = Nokogiri::XML(xml)
        fs = doc.children.first
        fs.name.should == "FolderShape"
        fs.children.size.should == 2

        bs = fs.children.first
        bs.name.should == "BaseShape"
        bs.content.should == "IdOnly"

        ap = fs.children[1]
        ap.name.should == "AdditionalProperties"
        ap.children.size.should == 2

        fid = ap.children.first
        fid.name.should == "FieldURI"
        fid[:FieldURI].should == "folder:FolderId"
        fid.children.size.should == 0

        ftot = ap.children[1]
        ftot.name.should == "FieldURI"
        ftot[:FieldURI].should == "folder:TotalCount"
        ftot.children.size.should == 0
      end
    end
  end
end
