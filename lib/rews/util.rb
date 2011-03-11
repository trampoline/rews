require 'set'

module Rews
  module Util
    module_function

    # checks an options hash against a constraints hash
    # non-nil values in the constraints hash indicates required options,
    # nil values indicates optional options
    def check_opts(opts, constraints)
      required = constraints.select{|k,v| v}.map{|k,v| k}
      optional = constraints.keys - required

      opts.keys.each do |key|
        raise "unknown option: #{key}" if !required.delete(key) && !optional.delete(key)
      end
      raise "required options not given: #{required.inspect}" if required.size>0
      true
    end
  end
end
