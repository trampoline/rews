require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Client do
    it "should create new DistinguishedFolderIds for arbitrary mailboxes" do
      client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")

      mock(Folder::DistinguishedFolderId).new(client, 'inbox', 'foo@bar.com')

      client.distinguished_folder_id('inbox', 'foo@bar.com')
    end

    it "should create new DistinguishedFolderIds for the default mailbox" do
      client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")

      mock(Folder::DistinguishedFolderId).new(client, 'inbox', nil)

      client.distinguished_folder_id('inbox')
    end

    describe "create_item" do
      def test_create_item(client, items, &validate_block)
        response = Object.new
        mock(response).to_hash{{:create_item_response=>{:response_messages=>{:create_item_response_message=>{:response_class=>"Success"}}}}}

        RequestProxy.mock_request(self, 
                                  client, 
                                  "CreateItem",
                                  {},
                                  response,
                                  &validate_block)
        client.create_item(:items=>items)
      end

      it "should create a CreateItem request and render the Items to the body" do
        client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
        test_create_item(client, [[:suppress_read_receipt, [:reference_item_id, {:id=>"abc", :change_key=>"def"}]]]) do |body|
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"}, :style=>:xml)
          rsxml.should == ["wsdl:Items",
                           ["t:SuppressReadReceipt",
                            ["t:ReferenceItemId", {"Id"=>"abc", "ChangeKey"=>"def"}]]]
        end
      end
    end

    describe "suppress_read_receipt" do
      def test_suppress_read_receipt(client, item_or_item_ids, &validate_block)
        response = Object.new
        mock(response).to_hash{{:create_item_response=>{:response_messages=>{:create_item_response_message=>{:response_class=>"Success"}}}}}

        RequestProxy.mock_request(self, 
                                  client, 
                                  "CreateItem",
                                  {},
                                  response,
                                  &validate_block)
        client.suppress_read_receipt(item_or_item_ids)
      end

      it "should send a CreateItemRequest with SuppressReadReceipt items for each ItemId" do
        client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
        test_suppress_read_receipt(client, [Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"}),
                                             Item::ItemId.new(client, {:id=>"ghi", :change_key=>"jkl"})]) do |body|
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"}, :style=>:xml)
          rsxml.should ==  ["wsdl:Items",
                            ["t:SuppressReadReceipt",
                             ["t:ReferenceItemId", {"Id"=>"abc", "ChangeKey"=>"def"}]],
                            ["t:SuppressReadReceipt",
                             ["t:ReferenceItemId", {"Id"=>"ghi", "ChangeKey"=>"jkl"}]]]
        end
      end

      it "should send a CreateItemRequest with SuppressReadReceipt items for each Item" do
        client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
        test_suppress_read_receipt(client, [Item::Item.new(client, 'Message', {:item_id=>{:id=>'abc', :change_key=>'def'}}),
                                             Item::Item.new(client, 'Message', {:item_id=>{:id=>'ghi', :change_key=>'jkl'}})]) do |body|
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"}, :style=>:xml)
          rsxml.should ==  ["wsdl:Items",
                            ["t:SuppressReadReceipt",
                             ["t:ReferenceItemId", {"Id"=>"abc", "ChangeKey"=>"def"}]],
                            ["t:SuppressReadReceipt",
                             ["t:ReferenceItemId", {"Id"=>"ghi", "ChangeKey"=>"jkl"}]]]
        end
      end

      it "should send a CreateItemRequest with SuppressReadReceipt for each item in a FindResult" do
        client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
        fr = Folder::FindResult.new({}){[Item::Item.new(client, 'Message', {:item_id=>{:id=>'abc', :change_key=>'def'}}),
                                         Item::Item.new(client, 'Message', {:item_id=>{:id=>'ghi', :change_key=>'jkl'}})]}
        test_suppress_read_receipt(client, fr) do |body|
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"}, :style=>:xml)
          rsxml.should ==  ["wsdl:Items",
                            ["t:SuppressReadReceipt",
                             ["t:ReferenceItemId", {"Id"=>"abc", "ChangeKey"=>"def"}]],
                            ["t:SuppressReadReceipt",
                             ["t:ReferenceItemId", {"Id"=>"ghi", "ChangeKey"=>"jkl"}]]]
        end
      end

      it "should filter Items with IsRead=true or IsReadReceiptRequested=false before making request" do
        client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
        test_suppress_read_receipt(client, [Item::Item.new(client, 
                                                            'Message', 
                                                            {:item_id=>{:id=>'abc', :change_key=>'def'},
                                                              :is_read=>true}),
                                             Item::Item.new(client, 'Message', {:item_id=>{:id=>'ghi', :change_key=>'jkl'}}),
                                             Item::Item.new(client, 
                                                            'Message',
                                                            {:item_id=>{:id=>'mno', :change_key=>'pqr'},
                                                              :is_read_receipt_requested=>false})]) do |body|
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"}, :style=>:xml)
          rsxml.should == ["wsdl:Items",
                           ["t:SuppressReadReceipt",
                            ["t:ReferenceItemId", {"Id"=>"ghi", "ChangeKey"=>"jkl"}]]]
        end
      end
    end

      describe "get_item" do
        def test_get_item(client, item_shape, ignore_change_keys, message_ids, result)
          shape = Object.new
          mock(Shape::ItemShape).new(item_shape||{}){shape}
          mock(shape).to_xml{""}
          
          message_ids = message_ids.result if message_ids.is_a?(Folder::FindResult)
          message_ids.each do |mid|
            if mid.is_a?(Item::Item)
              mock(mid.item_id).to_xml(ignore_change_keys){""}
            else
              mock(mid).to_xml(ignore_change_keys){""}
            end
          end
          
          response = Object.new
          mock(response).to_hash{{:get_item_response=>{:response_messages=>{:get_item_response_message=>{:response_class=>"Success", :items=>result}}}}}
          
          RequestProxy.mock_request(self, client, "GetItem", nil, response)
          
          opts = {}
          opts[:item_shape]=item_shape if item_shape
          opts[:ignore_change_keys]=ignore_change_keys if ignore_change_keys
          client.get_item(message_ids, opts)
        end

        it "should generate xml including all provided ItemIds and parse response" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          items = test_get_item(client,
                                {:base_shape=>:IdOnly},
                                nil,
                                [Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"})],
                                {:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}})
          items.size.should == 1
          msg=items.first
          msg.item_id.should == Item::ItemId.new(client, :id=>"abc", :change_key=>"def")
        end

        it "should generate xml ignoring change keys if requested and parsing a response with multiple items" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          items = test_get_item(client,
                                {:base_shape=>:Default},
                                true,
                                [Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"}),
                                 Item::ItemId.new(client, {:id=>"ghi", :change_key=>"jkl"})],
                                {:message=>[{:item_id=>{:id=>"abc", :change_key=>"def"}},
                                            {:item_id=>{:id=>"ghi", :change_key=>"jkl"}}]})
          items.size.should == 2
          items.first.item_id.should == Item::ItemId.new(client, :id=>"abc", :change_key=>"def")
          items[1].item_id.should == Item::ItemId.new(client, :id=>"ghi", :change_key=>"jkl")
        end

        it "should extract ItemIds from Items if items are provided as identifiers" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          items = test_get_item(client,
                                {:base_shape=>:Default},
                                true,
                                [Item::Item.new(client, :message, {:item_id=>{:id=>"abc", :change_key=>"def"}}),
                                 Item::Item.new(client, :message, {:item_id=>{:id=>"ghi", :change_key=>"jkl"}})],
                                {:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}})
        end

        it "should extract results from a FindResult if a FindResult is provided for identifiers" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          items = test_get_item(client,
                                {:base_shape=>:Default},
                                true,
                                Folder::FindResult.new({}) {
                                  [Item::Item.new(client, :message, {:item_id=>{:id=>"abc", :change_key=>"def"}}),
                                   Item::Item.new(client, :message, {:item_id=>{:id=>"ghi", :change_key=>"jkl"}})]},
                                {:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}})
        end
      end



      describe "update_item" do
        def test_update_item(client,
                             conflict_resolution, 
                             message_disposition,
                             ignore_change_keys,
                             updates,
                             message_ids,
                             &validate_block)
          
          message_ids = message_ids.result if message_ids.is_a?(Folder::FindResult)
          message_ids.each do |mid|
            if mid.is_a?(Item::Item)
              proy(mid.item_id).to_xml(ignore_change_keys)
            else
              proxy(mid).to_xml(ignore_change_keys)
            end
          end
          
          response = Object.new
          mock(response).to_hash{{:update_item_response=>{:response_messages=>{:update_item_response_message=>{:response_class=>"Success"}}}}}
          
          RequestProxy.mock_request(self, client, "UpdateItem",  
                                    { :ConflictResolution=>conflict_resolution || "AutoResolve",
                                      :MessageDisposition=>message_disposition || "SaveOnly"}, 
                                    response,
                                    &validate_block)
          
          opts = {}
          opts[:conflict_resolution]=conflict_resolution if conflict_resolution
          opts[:message_disposition]=message_disposition if message_disposition
          opts[:ignore_change_keys]=ignore_change_keys if !ignore_change_keys.nil?
          opts[:updates]=updates
          client.update_item(message_ids, opts)
        end

        it "should generate body xml and parse response for a single update" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          test_update_item(client, nil, nil, nil,
                           SetItemField.new("message:IsRead", [:message, [:is_read, "true"]]),
                           [Item::ItemId.new(client, :id=>"abc", :change_key=>"def")]) do |body|
            
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
        
        it "should generate body xml and parse response for a multiple updates of multiple items" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          test_update_item(client, nil, nil, nil,
                           [SetItemField.new("message:IsRead", [:message, [:is_read, "true"]]),
                            SetItemField.new("item:Blah", [:item, [:blah, "blah"]])],
                           [Item::ItemId.new(client, :id=>"abc", :change_key=>"def"),
                            Item::ItemId.new(client, :id=>"ghi", :change_key=>"jkl")]) do |body|
            
            rsxml = Rsxml.to_rsxml(body, :ns=>{:wsdl=>"ews_wsdl", :t=>"ews_types", ""=>"ews_wsdl"}, :style=>:xml)
            Rsxml.compare(rsxml, ["wsdl:ItemChanges",
                                  ["t:ItemChange",
                                   ["t:ItemId", {"Id"=>"abc", "ChangeKey"=>"def"}],
                                   ["t:Updates",
                                    ["t:SetItemField",
                                     ["t:FieldURI", {"FieldURI"=>"message:IsRead"}],
                                     ["t:Message", ["t:IsRead", "true"]]],
                                    ["t:SetItemField",
                                     ["t:FieldURI", {"FieldURI"=>"item:Blah"}],
                                     ["t:Item", ["t:Blah", "blah"]]]]],
                                  ["t:ItemChange",
                                   ["t:ItemId", {"Id"=>"ghi", "ChangeKey"=>"jkl"}],
                                   ["t:Updates",
                                    ["t:SetItemField",
                                     ["t:FieldURI", {"FieldURI"=>"message:IsRead"}],
                                     ["t:Message", ["t:IsRead", "true"]]],
                                    ["t:SetItemField",
                                     ["t:FieldURI", {"FieldURI"=>"item:Blah"}],
                                     ["t:Item", ["t:Blah", "blah"]]]]]]).should == true  
          end
        end
        
      end



      describe "delete_item" do
        def test_delete_item(client, delete_type, ignore_change_keys, message_ids)
          message_ids = message_ids.result if message_ids.is_a?(Folder::FindResult)
          message_ids.each do |mid|
            if mid.is_a?(Item::Item)
              mock(mid.item_id).to_xml(ignore_change_keys){""}
            else
              mock(mid).to_xml(ignore_change_keys){""}
            end
          end
          
          response = Object.new
          mock(response).to_hash{{:delete_item_response=>{:response_messages=>{:delete_item_response_message=>{:response_class=>"Success"}}}}}
          
          RequestProxy.mock_request(self, client, "DeleteItem", {:DeleteType=>delete_type}, response)
          
          opts = {}
          opts[:delete_type]=delete_type if delete_type
          opts[:ignore_change_keys]=ignore_change_keys if ignore_change_keys
          client.delete_item(message_ids, opts)
        end

        it "should generate xml including a single ItemId" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          test_delete_item(client, :HardDelete, nil, [Item::ItemId.new(client, :id=>"abc", :change_key=>"def")])
        end
        
        it "should generate xml ignoring change keys and including multiple ItemIds" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          test_delete_item(client, 
                           :HardDelete, 
                           true, 
                           [Item::ItemId.new(client, :id=>"abc", :change_key=>"def"),
                           Item::ItemId.new(client, :id=>"ghi", :change_key=>"jkl")])
        end

        it "should extract ItemIds from Items if Items are provided as identifiers" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          test_delete_item(client, 
                           :HardDelete, 
                           true, 
                           [Item::Item.new(client, :message, {:item_id=>{:id=>"abc", :change_key=>"def"}}),
                            Item::Item.new(client, :message, {:item_id=>{:id=>"ghi", :change_key=>"jkl"}})])
        end

        it "should extract ItemIds from a FindResult if a FindResult is provided as identifiers" do
          client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
          test_delete_item(client, 
                           :HardDelete, 
                           true, 
                           Folder::FindResult.new({}) {[Item::Item.new(client, :message, {:item_id=>{:id=>"abc", :change_key=>"def"}}),
                                                        Item::Item.new(client, :message, {:item_id=>{:id=>"ghi", :change_key=>"jkl"}})]})
        end
      end


  end
end
