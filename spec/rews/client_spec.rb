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
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"})
          rsxml.should == ["wsdl:CreateItem", {"xmlns:wsdl"=>"ews_wsdl", "xmlns:t"=>"ews_types"},
                           ["t:Items",
                            ["t:SuppressReadReceipt",
                             ["t:ReferenceItemId", {"Id"=>"abc", "ChangeKey"=>"def"}]]]]
        end
      end
    end

    describe "suppress_read_receipts" do
      def test_suppress_read_receipts(client, item_or_item_ids, &validate_block)
        response = Object.new
        mock(response).to_hash{{:create_item_response=>{:response_messages=>{:create_item_response_message=>{:response_class=>"Success"}}}}}

        RequestProxy.mock_request(self, 
                                  client, 
                                  "CreateItem",
                                  {},
                                  response,
                                  &validate_block)
        client.suppress_read_receipts(item_or_item_ids)
      end

      it "should send a CreateItemRequest with SuppressReadReceipt items for each ItemId" do
        client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
        test_suppress_read_receipts(client, [Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"}),
                                             Item::ItemId.new(client, {:id=>"ghi", :change_key=>"jkl"})]) do |body|
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"})
          rsxml.should ==  ["wsdl:CreateItem", {"xmlns:wsdl"=>"ews_wsdl", "xmlns:t"=>"ews_types"},
                            ["t:Items",
                             ["t:SuppressReadReceipt",
                              ["t:ReferenceItemId", {"Id"=>"abc", "ChangeKey"=>"def"}]],
                             ["t:SuppressReadReceipt",
                              ["t:ReferenceItemId", {"Id"=>"ghi", "ChangeKey"=>"jkl"}]]]]
        end
      end

      it "should send a CreateItemRequest with SuppressReadReceipt items for each Item" do
        client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
        test_suppress_read_receipts(client, [Item::Item.new(client, 'Message', {:item_id=>{:id=>'abc', :change_key=>'def'}}),
                                             Item::Item.new(client, 'Message', {:item_id=>{:id=>'ghi', :change_key=>'jkl'}})]) do |body|
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"})
          rsxml.should ==  ["wsdl:CreateItem", {"xmlns:wsdl"=>"ews_wsdl", "xmlns:t"=>"ews_types"},
                            ["t:Items",
                             ["t:SuppressReadReceipt",
                              ["t:ReferenceItemId", {"Id"=>"abc", "ChangeKey"=>"def"}]],
                             ["t:SuppressReadReceipt",
                              ["t:ReferenceItemId", {"Id"=>"ghi", "ChangeKey"=>"jkl"}]]]]
        end
      end

      it "should filter Items with IsRead=true or IsReadReceiptRequested=false before making request" do
        client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")
        test_suppress_read_receipts(client, [Item::Item.new(client, 
                                                            'Message', 
                                                            {:item_id=>{:id=>'abc', :change_key=>'def'},
                                                              :is_read=>true}),
                                             Item::Item.new(client, 'Message', {:item_id=>{:id=>'ghi', :change_key=>'jkl'}}),
                                             Item::Item.new(client, 
                                                            'Message',
                                                            {:item_id=>{:id=>'mno', :change_key=>'pqr'},
                                                              :is_read_receipt_requested=>false})]) do |body|
          rsxml = Rsxml.to_rsxml(body, :ns=>{"wsdl"=>"ews_wsdl", "t"=>"ews_types"})
          rsxml.should == ["wsdl:CreateItem", {"xmlns:wsdl"=>"ews_wsdl", "xmlns:t"=>"ews_types"},
                           ["t:Items",
                            ["t:SuppressReadReceipt",
                             ["t:ReferenceItemId", {"Id"=>"ghi", "ChangeKey"=>"jkl"}]]]]
        end
      end
    end
  end
end
