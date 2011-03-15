require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe View do
    describe View::IndexedPageItemView do
      it "should write IndexedPageItemView xml" do
        xml = View::IndexedPageItemView.new(:max_entries_returned=>10,
                                            :offset=>10,
                                            :base_point=>:End).to_xml

        doc = Nokogiri::XML(xml)
        ipiv = doc.children.first
        ipiv.name.should == "IndexedPageItemView"
        ipiv[:MaxEntriesReturned].should == "10"
        ipiv[:Offset].should == "10"
        ipiv[:BasePoint].should == "End"
      end
    end

    describe View::IndexedPageFolderView do
      it "should write an IndexedPageFolderView" do
        xml = View::IndexedPageFolderView.new(:max_entries_returned=>10,
                                              :offset=>10,
                                              :base_point=>:End).to_xml

        doc = Nokogiri::XML(xml)
        ipiv = doc.children.first
        ipiv.name.should == "IndexedPageFolderView"
        ipiv[:MaxEntriesReturned].should == "10"
        ipiv[:Offset].should == "10"
        ipiv[:BasePoint].should == "End"
      end
    end
  end
end
