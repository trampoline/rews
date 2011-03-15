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

    describe Folder::DistinguishedFolderId do
      it "should generate DistinguishedFolderId xml for the default mailbox" do
        client = Object.new
        xml = Folder::DistinguishedFolderId.new(client, 'inbox').to_xml
        doc = Nokogiri::XML(xml)
        dfid=doc.children.first
        dfid.name.should == "DistinguishedFolderId"
        dfid[:Id].should == 'inbox'
        dfid.children.size.should == 0
      end

      it "should generate DistinguishedFolderId xml for a specified mailbox" do
        client = Object.new
        xml = Folder::DistinguishedFolderId.new(client, 'inbox', 'foo@bar.com').to_xml
        doc = Nokogiri::XML(xml)
        dfid=doc.children.first
        dfid.name.should == "DistinguishedFolderId"
        dfid[:Id].should == 'inbox'
        dfid.children.size.should == 1

        mb = dfid.children.first
        mb.name.should == "Mailbox"
        mb.children.size.should == 1

        ea = mb.children.first
        ea.name.should == "EmailAddress"
        ea.content.should == 'foo@bar.com'
        ea.children.size.should == 1 # the content
      end
    end

    describe Folder::VanillaFolderId do
      it "should generate FolderId xml with a change_key" do
        client = Object.new
        xml = Folder::VanillaFolderId.new(client, {:id=>"abc", :change_key=>"def"}).to_xml
        doc = Nokogiri::XML(xml)
        fid=doc.children.first
        fid.name.should=="FolderId"
        fid[:Id].should == "abc"
        fid[:ChangeKey].should == "def"
      end

      it "should generate FolderId without a change_key" do
        client = Object.new
        xml = Folder::VanillaFolderId.new(client, {:id=>"abc"}).to_xml
        doc = Nokogiri::XML(xml)
        fid=doc.children.first
        fid.name.should=="FolderId"
        fid[:Id].should == "abc"
        fid[:ChangeKey].should == nil
      end
    end

    describe Folder::BaseFolderId do
    end
  end
end
