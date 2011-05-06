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
      it "should create a JSON compatible key" do
        client = Object.new
        dfid = Folder::DistinguishedFolderId.new(client, 'inbox')
        dfid.key.should == ["distinguished_folder", 'inbox']
        dfid.key(true).should == ["distinguished_folder", 'inbox']
      end

      it "should create a JSON compatible key with a specified mailbox" do
        client = Object.new
        dfid = Folder::DistinguishedFolderId.new(client, 'inbox', "foo@bar.com")
        dfid.key.should == ["distinguished_folder", 'inbox', "foo@bar.com"]
        dfid.key(true).should == ["distinguished_folder", 'inbox', "foo@bar.com"]
      end

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
      it "should create a JSON compatible key" do
        client = Object.new
        dfid = Folder::VanillaFolderId.new(client, {:id=>'abc', :change_key=>"def"})
        dfid.key.should == ["folder", 'abc', 'def']
        dfid.key(true).should == ["folder", 'abc']
      end
      
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
      describe "find_folder" do
        def test_find_folder(client, folder_shape, indexed_page_folder_view, restriction, result)
          shape = Object.new
          mock(Shape::FolderShape).new(folder_shape||{}){shape}
          mock(shape).to_xml{""}

          if indexed_page_folder_view
            view = Object.new
            mock(View::IndexedPageFolderView).new(indexed_page_folder_view){view}
            mock(view).to_xml{""}
          end

          if restriction
            r = Object.new
            mock(Restriction).new(restriction){r}
            mock(r).to_xml{""}
          end

          fid = Folder::DistinguishedFolderId.new(client, 'blah')
          mock.proxy(fid).to_xml

          response = Object.new
          mock(response).to_hash{{:find_folder_response=>{:response_messages=>{:find_folder_response_message=>{:response_class=>"Success", :root_folder=>result}}}}}

          RequestProxy.mock_request(self, client, "FindFolder", {"Traversal"=>"Shallow"}, response)

          opts = {}
          opts[:folder_shape] = folder_shape if folder_shape
          opts[:indexed_page_folder_view] = indexed_page_folder_view if indexed_page_folder_view
          opts[:restriction] = restriction if restriction
          fid.find_folder(opts)
        end

        it "should generate minimal xml and parse a response with one folder" do
          client = Object.new
          folders = test_find_folder(client,
                                     {:base_shape=>:IdOnly},
                                     nil,
                                     nil,
                                     {:includes_last_item_in_range=>false,
                                       :indexed_paging_offset=>0,
                                       :total_items_in_view=>1,
                                       :folders=>{:folder=>{:folder_id=>{:id=>"abc", :change_key=>"def"}}}})
          folders.includes_last_item_in_range.should == false
          folders.indexed_paging_offset.should == 0
          folders.total_items_in_view.should == 1
          folders.result.first.should == Folder::Folder.new(client, :folder_id=>{:id=>"abc", :change_key=>"def"})
          
        end

        it "should parse a response with no folders" do
          client = Object.new
          folders = test_find_folder(client,
                                     {:base_shape=>:IdOnly},
                                     nil,
                                     nil,
                                     {:includes_last_item_in_range=>false,
                                       :indexed_paging_offset=>0,
                                       :total_items_in_view=>0,
                                       :folders=>nil})
          folders.result.should == []
        end

        it "should generate xml with indexed_page_folder_view and parse a response with multiple folders" do
          client = Object.new
          folders = test_find_folder(client,
                                     {:base_shape=>:Default},
                                     {:max_entries_returned=>10, :offset=>10, :base_point=>:Beginning},
                                     [[:== , "item:DateTimeReceived", DateTime.now]],
                                     {:includes_last_item_in_range=>true,
                                       :indexed_paging_offset=>10,
                                       :total_items_in_view=>5,
                                       :folders=>{:folder=>[{:folder_id=>{:id=>"abc", :change_key=>"def"}},
                                                            {:folder_id=>{:id=>"ghi", :change_key=>"jkl"}}]}})
          folders.includes_last_item_in_range.should == true
          folders.indexed_paging_offset.should == 10
          folders.total_items_in_view.should == 5
          folders.result.first.should == Folder::Folder.new(client, :folder_id=>{:id=>"abc", :change_key=>"def"})
          folders.result[1].should == Folder::Folder.new(client, :folder_id=>{:id=>"ghi", :change_key=>"jkl"})
        end
      end

      describe "find_folder_id" do
        it "should call find_folder with a default BaseShape of IdOnly" do
          client=Object.new

          fid = Folder::DistinguishedFolderId.new(client, 'blah')
          
          opts = {:indexed_page_folder_view=>{:max_entries_returned=>10, :offset=>10, :base_point=>:Beginning},
            :restriction=>[[:==, "item:DateTimeReceived", DateTime.now]]}
          mock(fid).find_folder(opts){Folder::FindResult.new(:includes_last_item_in_range=>true, :indexed_paging_offset=>10, :total_items_in_view=>3){[Folder::Folder.new(client, {:folder_id=>{:id=>"abc", :change_key=>"def"}})]}}
          
          fres = fid.find_folder_id(opts)
          fres.includes_last_item_in_range.should == true
          fres.indexed_paging_offset.should == 10
          fres.total_items_in_view.should == 3
        end
      end

      def test_find_item(client, item_shape, indexed_page_item_view, restriction, result)
        shape = Object.new
        mock(Shape::ItemShape).new(item_shape||{}){shape}
        mock(shape).to_xml{""}

        if indexed_page_item_view
          view = Object.new
          mock(View::IndexedPageItemView).new(indexed_page_item_view){view}
          mock(view).to_xml{""}
        end

        if restriction
          r = Object.new
          mock(Restriction).new(restriction){r}
          mock(r).to_xml{""}
        end

        fid = Folder::DistinguishedFolderId.new(client, 'blah')
        mock.proxy(fid).to_xml

        response = Object.new
        mock(response).to_hash{{:find_item_response=>{:response_messages=>{:find_item_response_message=>{:response_class=>"Success", :root_folder=>result}}}}}

        RequestProxy.mock_request(self, client, "FindItem", {"Traversal"=>"Shallow"}, response)

        opts = {}
        opts[:item_shape] = item_shape if item_shape
        opts[:indexed_page_item_view] = indexed_page_item_view if indexed_page_item_view
        opts[:restriction] = restriction if restriction
        fid.find_item(opts)
      end
      
      describe "find_item" do
        it "should parse a response with no items" do
          client = Object.new
          items = test_find_item(client,
                                 {:base_shape=>:IdOnly},
                                 nil,
                                 nil,
                                 {:includes_last_item_in_range=>false,
                                   :indexed_paging_offset=>10,
                                   :total_items_in_view=>0,
                                   :items=>nil})
          items.indexed_paging_offset.should == 10
          items.total_items_in_view.should == 0
          items.result.should == []
        end

        it "should generate minimal xml and parse a response with one item" do
          client = Object.new
          items = test_find_item(client,
                                 {:base_shape=>:IdOnly},
                                 nil,
                                 nil,
                                 {:includes_last_item_in_range=>false,
                                   :indexed_paging_offset=>0,
                                   :total_items_in_view=>1,
                                   :items=>{:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}}})
          items.includes_last_item_in_range.should == false
          items.indexed_paging_offset.should == 0
          items.total_items_in_view.should == 1
          items.result.size.should == 1
          items.result.first.should == Item::Item.new(client, :message, :item_id=>{:id=>"abc", :change_key=>"def"})
        end

        it "should generate xml with indexed_page_folder_view and parse a response with multiple folders" do
          client = Object.new
          items = test_find_item(client,
                                 {:base_shape=>:IdOnly},
                                 {:max_entries_returned=>10, :offset=>10, :base_point=>:Beginning},
                                 [[:== , "item:DateTimeReceived", DateTime.now]],
                                 {:includes_last_item_in_range=>false,
                                   :indexed_paging_offset=>0,
                                   :total_items_in_view=>1,
                                   :items=>{:message=>[{:item_id=>{:id=>"abc", :change_key=>"def"}},
                                                       {:item_id=>{:id=>"ghi", :change_key=>"jkl"}}]}})
          items.includes_last_item_in_range.should == false
          items.indexed_paging_offset.should == 0
          items.total_items_in_view.should == 1
          items.result.size.should == 2
          items.result.first.should == Item::Item.new(client, :message, :item_id=>{:id=>"abc", :change_key=>"def"})
          items.result[1].should == Item::Item.new(client, :message, :item_id=>{:id=>"ghi", :change_key=>"jkl"})
        end
      end

      describe "find_item_id" do
        it "should call find_folder with a default BaseShape of IdOnly" do
          client=Object.new

          fid = Folder::DistinguishedFolderId.new(client, 'blah')
          
          opts = {
            :indexed_page_item_view=>{:max_entries_returned=>10, :offset=>10, :base_point=>:Beginning}
          }

          mock(fid).find_item(opts.merge(:item_shape=>{:base_shape=>:IdOnly})) do
            Folder::FindResult.new(:includes_last_item_in_range=>false, 
                                   :indexed_paging_offset=>10, 
                                   :total_items_in_view=>10) do
              [Item::Item.new(client, :message, {:item_id=>{:id=>"abc", :change_key=>"def"}})]
            end
          end
          
          res = fid.find_item_id(opts)
          res.includes_last_item_in_range.should == false
          res.indexed_paging_offset.should == 10
          res.total_items_in_view.should == 10
        end
      end



    end
  end
end
