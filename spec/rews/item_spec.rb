require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Item do
    describe Item::Item do
      it "should parse the item_id and attributes from the XML hash" do
        client = Object.new

        i = Item::Item.new(client, 'Message', {:item_id=>{:id=>'1234', :change_key=>'abcd'}, :foo=>100})

        i.client.should == client
        i.item_class.should == 'Message'
        i.item_id.should == Item::ItemId.new(client, {:id=>'1234', :change_key=>'abcd'})

        i[:foo].should == 100
      end
    end

    describe Item::ItemId do

      describe "to_xml" do
        it "should generate an ItemId with change_key by default" do
          client = Object.new
          xml = Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"}).to_xml
          doc = Nokogiri::XML(xml)
          id=doc.children.first
          id.name.should == "ItemId"
          id[:Id].should == "abc"
          id[:ChangeKey].should == "def"
        end

        it "should generate an ItemId without change_key if requested" do
          client = Object.new
          xml = Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"}).to_xml(true)
          doc = Nokogiri::XML(xml)
          id=doc.children.first
          id.name.should == "ItemId"
          id[:Id].should == "abc"
          id[:ChangeKey].should == nil
        end
      end

      def mock_request(client, action, attrs, response)
        # deal with different call arity
        mock(client).savon_client.mock!.request(*[:wsdl, action, attrs].compact) do |*args|
          block = args.last # block is the last arg

          ctx = RequestProxy.new()
          ns = Object.new
          mock(ctx.soap).namespaces{ns}
          mock(ns)["xmlns:t"]=Rews::SCHEMA_TYPES
          mock(ctx.soap).body=(anything)
          
          ctx.eval_with_delegation(&block)
          response
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

          mock_request(client, "GetItem", nil, response)

          opts={}
          opts[:item_shape]=item_shape if item_shape
          opts[:ignore_change_keys]=ignore_change_keys if ignore_change_keys
          iid.get_item(opts)
        end

        it "should generate the BaseShape and ItemId xml and parse the response" do
          client = Object.new
          msg = test_get_item(client,
                              {:base_shape=>:IdOnly}, 
                              nil, 
                              {:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}})
          msg.item_class.should == :message
          msg.item_id.should == Item::ItemId.new(client, :id=>"abc", :change_key=>"def")
        end

        it "should generate a request with no change_key if specified" do
          client = Object.new
          msg = test_get_item(client,
                              {:base_shape=>:Default}, 
                              true, 
                              {:message=>{:item_id=>{:id=>"abc", :change_key=>"def"}}})
          msg.item_class.should == :message
          msg.item_id.should == Item::ItemId.new(client, :id=>"abc", :change_key=>"def")
        end

      end

      describe "delete_item" do
        def test_delete_item(client, ignore_change_keys, delete_type)
          iid = Item::ItemId.new(client, {:id=>"abc", :change_key=>"def"})
          mock.proxy(iid).to_xml(ignore_change_keys){""}

          response = Object.new
          mock(response).to_hash{{:delete_item_response=>{:response_messages=>{:delete_item_response_message=>{:response_class=>"Success"}}}}}

          mock_request(client, "DeleteItem", {:DeleteType=>delete_type}, response)

          opts={}
          opts[:ignore_change_keys]=ignore_change_keys if ignore_change_keys
          opts[:delete_type] = delete_type
          iid.delete_item(opts)
        end

        it "should generate the ItemId xml and parse the response" do
          client = Object.new
          msg = test_delete_item(client, true, :HardDelete)
        end
      end
    end
  end
end
