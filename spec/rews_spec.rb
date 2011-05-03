require File.expand_path("../spec_helper", __FILE__)

module Rews
  describe "log" do
    it "should log to a logger if set" do
      logger = Object.new
      stub(Rews).logger{logger}
      mock(logger).warn("boo")

      Rews.log{|l| l.warn("boo")}.should == nil
    end

    it "should do nothing if no logger set" do
      stub(Rews).logger{nil}
      lambda {
        Rews.log{|l| raise "boo"}.should == nil
      }.should_not raise_error
    end
  end

end
