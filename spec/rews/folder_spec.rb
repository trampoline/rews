require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Folder do
    describe Folder::Folder do
      it "should parse the folder_id and attributes from the XML hash" do
        client = Object.new

        i = Folder::Folder.new(client, {:folder_id=>{:id=>"abc", :change_key=>'def'}, :foo=>100})
        i.client.should == client
        i.folder_id.should == Folder::VanillaFolderId.new(client, {:id=>'abc', :change_key=>"def"})
        i[:foo].should == 100
      end
    end

    describe Folder::BaseFolderId do
    end

    describe Folder::VanillaFolderId do
    end

    describe Folder::DistinguishedFolderId do
    end
  end
end
