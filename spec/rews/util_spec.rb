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
    end

    describe "single_error_check" do
      it "should raise an error description of the response_class is Error" do
      end

      it "should log a warning and return if the response_class is Warning" do
      end

      it "should return if the response_class is Success" do
      end
    end
  end
end
