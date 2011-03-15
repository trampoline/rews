# a stand-in for a Savon Client, which does instance_eval with delegation
# like the Savon Client
class RequestProxy
  attr_accessor :soap
  def initialize
    @soap=Object.new
  end

  def eval_with_delegation(&block)
    @self_before_instance_eval = eval "self", block.binding
    instance_eval &block
  end

  def method_missing(method, *args, &block)
    @self_before_instance_eval.send method, *args, &block
  end
end

