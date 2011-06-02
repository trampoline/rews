require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Item do
    def client
      Object.new
    end

    describe "read_items" do
      it "should parse a list of zero items correctly" do
        c = client
        items = Item.read_items(c, nil)
        items.should == []
      end

      it "should parse a list of one items correctly" do
        c = client
        items = Item.read_items(c, {:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}})
        items.length.should == 1
        item = items.first
        item.item_id.should == Item::ItemId.new(c, {:id=>"abc", :change_key=>"def"})
        item.item_class.should == :message
      end

      it "should parse a list of more than one item correctly" do
        c = client
        items = Item.read_items(c, {:message=>[{:item_id=>{:id=>"abc", :change_key=>"def"}},
                                               {:item_id=>{:id=>"ghi", :change_key=>"jkl"}}]})
        items.length.should == 2
        item1 = items.first
        item1.item_id.should == Item::ItemId.new(c, {:id=>"abc", :change_key=>"def"})
        item1.item_class.should == :message
        item2 = items.last
        item2.item_id.should == Item::ItemId.new(c, {:id=>"ghi", :change_key=>"jkl"})
        item2.item_class.should == :message
      end
    end

    describe "read_get_item_response_messages" do
      it "should parse a list of zero items correctly" do
        c = client
        items = Item.read_get_item_response_messages(c, {:items=>nil})
        items.should == []
      end
      
      it "should parse a list of one items correctly" do
        c = client
        items = Item.read_get_item_response_messages(c, {:items=>{:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}}})
        items.length.should == 1
        item = items.first
        item.item_id.should == Item::ItemId.new(c, {:id=>"abc", :change_key=>"def"})
        item.item_class.should == :message
      end

      it "should parse a list of more than one items correctly" do
        c = client
        items = Item.read_get_item_response_messages(c, {:items=>{:message=>[{:item_id=>{:id=>"abc", :change_key=>"def"}},
                                                                             {:item_id=>{:id=>"ghi", :change_key=>"jkl"}}]}})
        items.length.should == 2
        item1 = items.first
        item1.item_id.should == Item::ItemId.new(c, {:id=>"abc", :change_key=>"def"})
        item1.item_class.should == :message
        item2 = items.last
        item2.item_id.should == Item::ItemId.new(c, {:id=>"ghi", :change_key=>"jkl"})
        item2.item_class.should == :message      
      end
    end

    describe Item::Item do
      it "should parse the item_id and attributes from the XML hash" do
        c = client

        i = Item::Item.new(c, 'Message', {:item_id=>{:id=>'1234', :change_key=>'abcd'}, :foo=>100})

        i.client.should == c
        i.item_class.should == 'Message'
        i.item_id.should == Item::ItemId.new(c, {:id=>'1234', :change_key=>'abcd'})

        i[:foo].should == 100
      end
    end

    describe Item::ItemId do

      describe "to_xml" do
        it "should generate an ItemId with change_key by default" do
          c = client
          xml = Item::ItemId.new(c, {:id=>"abc", :change_key=>"def"}).to_xml
          doc = Nokogiri::XML(xml)
          id=doc.children.first
          id.name.should == "ItemId"
          id[:Id].should == "abc"
          id[:ChangeKey].should == "def"
        end

        it "should generate an ItemId without change_key if requested" do
          c = client
          xml = Item::ItemId.new(c, {:id=>"abc", :change_key=>"def"}).to_xml(true)
          doc = Nokogiri::XML(xml)
          id=doc.children.first
          id.name.should == "ItemId"
          id[:Id].should == "abc"
          id[:ChangeKey].should == nil
        end
      end

      describe "get_item" do
        def test_get_item(client, item_shape, ignore_change_keys, result)
          shape = Object.new
          mock(Shape::ItemShape).new(item_shape||{}){shape}
          mock(shape).to_xml{""}

          iid = Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"})
          mock.proxy(iid).to_xml(ignore_change_keys){""}

          response = Object.new
          mock(response).to_hash{{:get_item_response=>{:response_messages=>{:get_item_response_message=>{:response_class=>"Success", :items=>result}}}}}

          RequestProxy.mock_request(self, client, "GetItem", nil, response)

          opts={}
          opts[:item_shape]=item_shape if item_shape
          opts[:ignore_change_keys]=ignore_change_keys if ignore_change_keys
          iid.get_item(opts)
        end

        it "should generate the BaseShape and ItemId xml and parse the response" do
          c = client
          msg = test_get_item(c,
                              {:base_shape=>:IdOnly}, 
                              nil, 
                              {:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}})
          msg.item_class.should == :message
          msg.item_id.should == Item::ItemId.new(c, :id=>"abc", :change_key=>"def")
        end

        it "should generate a request with no change_key if specified" do
          c = client
          msg = test_get_item(c,
                              {:base_shape=>:Default}, 
                              true, 
                              {:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}})
          msg.item_class.should == :message
          msg.item_id.should == Item::ItemId.new(c, :id=>"abc", :change_key=>"def")
        end

      end

      describe "delete_item" do
        def test_delete_item(client, ignore_change_keys, delete_type)
          iid = Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"})
          mock.proxy(iid).to_xml(ignore_change_keys){""}

          response = Object.new
          mock(response).to_hash{{:delete_item_response=>{:response_messages=>{:delete_item_response_message=>{:response_class=>"Success"}}}}}

          RequestProxy.mock_request(self, client, "DeleteItem", {:DeleteType=>delete_type}, response)

          opts={}
          opts[:ignore_change_keys]=ignore_change_keys if ignore_change_keys
          opts[:delete_type] = delete_type
          iid.delete_item(opts)
        end

        it "should generate the ItemId xml and parse the response" do
          c = client
          msg = test_delete_item(c, true, :HardDelete)
        end
      end

      describe "update_item" do
        def test_update_item(client, 
                             conflict_resolution,
                             message_disposition, 
                             ignore_change_keys,
                             updates,
                             &validate_block)

          iid = Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"})
          mock.proxy(iid).to_xml(ignore_change_keys)

          response = Object.new
          mock(response).to_hash{{:update_item_response=>{:response_messages=>{:update_item_response_message=>{:response_class=>"Success"}}}}}

          RequestProxy.mock_request(self, client, "UpdateItem", 
                       { :ConflictResolution=>conflict_resolution,
                         :MessageDisposition=>message_disposition},
                       response,
                       &validate_block)

          opts={}
          opts[:conflict_resolution]=conflict_resolution if conflict_resolution
          opts[:message_disposition]=message_disposition if message_disposition
          opts[:ignore_change_keys]=ignore_change_keys if !ignore_change_keys.nil?
          opts[:updates]=updates
          iid.update_item(opts)
        end

        it "should generate the body xml and parse the response" do
          c = client
          # we test an array of updates, because rr stubbed objects bork on 1.9.2 with [*foo]
          update=[Object.new]
          stub(update[0]).to_xml{"blahblah"}
          msg = test_update_item(c, "AutoResolve", "SaveOnly", false, update) do |body|
            rsxml = Rsxml.to_rsxml(body, :ns=>{:wsdl=>"ews_wsdl", :t=>"ews_types"}, :style=>:xml)
            rsxml.should == ["wsdl:ItemChanges",
                             ["t:ItemChange",
                              ["t:ItemId", {"Id"=>"abc", "ChangeKey"=>"def"}],
                              ["t:Updates", "blahblah"]]]
          end
        end

        it "should raise an exception if no updates are given" do
          c = client
          iid = Item::ItemId.new(c, {:id=>"abc", :change_key=>"def"})

          lambda {
            iid.update_item({})
          }.should raise_error(/no updates/)
        end

      end

      describe "suppress_receipts" do
        def test_set_is_read(client, 
                             is_read,
                             &validate_block)

          iid = Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"})
          mock.proxy(iid).to_xml(nil)

          response = Object.new
          mock(response).to_hash{{:update_item_response=>{:response_messages=>{:update_item_response_message=>{:response_class=>"Success"}}}}}

          RequestProxy.mock_request(self, client, "UpdateItem", 
                       { :ConflictResolution=>"AlwaysOverwrite",
                         :MessageDisposition=>"SaveOnly"},
                       response,
                       &validate_block)

          opts={}
          opts[:conflict_resolution]="AlwaysOverwrite"
          opts[:message_disposition]="SaveOnly"
          iid.set_is_read(is_read)
        end

        it "should generate the body xml and parse the response" do
          c = client
          test_set_is_read(c, true) do |body|
            rsxml = Rsxml.to_rsxml(body, :ns=>{:wsdl=>"ews_wsdl", :t=>"ews_types", ""=>"ews_wsdl"}, :style=>:xml)
            Rsxml.compare(rsxml, ["wsdl:ItemChanges",
                                  ["t:ItemChange",
                                   ["t:ItemId", {"Id"=>"abc", "ChangeKey"=>"def"}],
                                   ["t:Updates",
                                    ["t:SetItemField",
                                     ["t:FieldURI", {"FieldURI"=>"message:IsRead"}],
                                     ["t:Message", ["t:IsRead", "true"]]]]]]).should == true
          end
          
        end
      end
    end
  end
end
