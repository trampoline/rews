require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Util do
    describe "strip_bang" do
      it "should strip the bang from the end of a String" do
        Util.strip_bang("foo!").should == "foo"
      end

      it "should strip the bank from the end of a Symbol" do
        Util.strip_bang(:foo! ).should == :foo
      end
    end

    describe "camelize" do
      it "should camelize a String" do
        Util.camelize("foo_bar").should == "FooBar"
      end
    end

    describe "camel_keys" do
      it "should camelize the keys of a Hash" do
        Util.camel_keys(:foo_bar=>1, "bar_baz"=>2, "bam"=>3).should ==
          {"FooBar"=>1, "BarBaz"=>2, "Bam"=>3}
      end
    end

    describe "with_error_check" do
      it "should yield, convert the response to a hash and fetch_in the status" do
        client = Object.new
        Util.with_error_check(client, :foo, :bar) do
          response_hash = {:foo=>{:bar=>{:response_class=>"Success"}}}
          response = Object.new
          mock(response).to_hash{response_hash}
          response
        end
      end

      it "should raise a Rews::Error if there are any errors" do
        client = Object.new
        lambda {
          Util.with_error_check(client, :foo, :bar) do
            response_hash = {:foo=>{:bar=>{:response_class=>"Error", :message_text=>"boo"}}}
            response = Object.new
            mock(response).to_hash{response_hash}
            response
          end
        }.should raise_error(Rews::Error)
      end

      it "should log any unexpected exceptions and tag with the savon response" do
        client = Object.new
        exception = RuntimeError.new("boo")
        mock(client).log do |block|
          logger = Object.new
          mock(logger).warn(exception)
          block.call(logger)
        end

        savon_response = Object.new

        lambda {
          Util.with_error_check(client, :foo, :bar) do
            mock(savon_response).to_hash{raise exception}
            savon_response
          end
        }.should raise_error{|error|
          error.respond_to?(:savon_response).should == true
          error.savon_response.should == savon_response
        }
      end
      
    end

    describe "single_error_check" do
      it "should return an error description of the response_class is Error" do
        client = Object.new
        status = {:response_class=>"Error", :message_text=>"boo", :response_code=>"BooError"}
        Util.single_error_check(client, status).should == "BooError - boo"
      end

      it "should log a warning and return if the response_class is Warning" do
        client = Object.new
        status = {:response_class=>"Warning", :message_text=>"boo", :response_code=>"BooWarning"}
        mock(client).log() do |p|
          logger = Object.new
          mock(logger).warn("BooWarning - boo")
          p.call(logger)
        end
        Util.single_error_check(client, status).should == nil
      end

      it "should return if the response_class is Success" do
        client = Object.new
        status = {:response_class=>"Success", :message_text=>nil, :response_code=>"Blah"}
        Util.single_error_check(client, status).should == nil
      end
    end

    describe "check_opts" do
      it "should raise if given an unknown option" do
        lambda {
          Util.check_opts({:foo=>nil}, {:foo=>1, :bar=>10})
        }.should raise_error(RuntimeError, /unknown option:.*bar/)
      end

      it "should fill in a default" do
        Util.check_opts({:foo=>10}, {}).should == {:foo=>10}
      end

      it "should not fill in a key if nil value given" do
        Util.check_opts({:foo=>nil}, {}).should == {}
      end

      it "should raise an error if a bang-suffixed option is not given" do
        lambda {
          Util.check_opts({:foo! =>nil}, {})
        }.should raise_error(RuntimeError, /required options not given:.*foo/)
      end

      it "should check_opts on sub-hashes if constraints sub-hashes given" do
        Util.check_opts({:foo=>{:bar=>10}}, {:foo=>{}}).should == {:foo=>{:bar=>10}}
      end
    end
  end
end
