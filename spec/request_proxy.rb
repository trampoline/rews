# a stand-in for a Savon Client, which does instance_eval with delegation
# like the Savon Client
class RequestProxy
  attr_accessor :soap
  attr_accessor :http
  def initialize
    soap_struct = Struct.new(:body)
    @soap = soap_struct.new
    @http=Object.new
  end

  def eval_with_delegation(&block)
    @self_before_instance_eval = eval "self", block.binding
    instance_eval &block
  end

  def method_missing(method, *args, &block)
    @self_before_instance_eval.send method, *args, &block
  end

  class << self
    # mocks a request to the savon client, and validates that the body xml generated
    # is correct
    def mock_request(example, client, action, attrs, response, &validate_block)
      # deal with different call arity
      example.mock(client).savon_client.mock!.request(*[:wsdl, action, attrs].compact) do |*args|
        block = args.last # block is the last arg

        ctx = RequestProxy.new()
        example.mock(ctx.http).headers.mock!["SOAPAction"]="\"#{Rews::SCHEMA_MESSAGES}/#{action}\""
        ns = Object.new
        example.mock(ctx.soap).namespaces{ns}
        example.mock(ns)["xmlns:t"]=Rews::SCHEMA_TYPES
        #          mock(ctx.soap).body=(anything)

        ctx.eval_with_delegation(&block)

        validate_block.call(ctx.soap.body) if validate_block
        response
      end
    end
  end
end

