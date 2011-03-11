require 'set'

module Rews
  module Util
    module_function

    # validates an options hash against a constraints hash
    # in the constraints hash :
    # - keys ending in ! indicate option is required
    # - keys not ending in ! indicate option is not required
    # - non-nil values provide defaults
    # - hash values provide constraints for sub-hashes
    def check_opts(constraints, opts={}, prefix=nil)
      required_keys = Hash[constraints.keys.select{|k| k.to_s[-1..-1] == '!'}.map{|k| [strip_bang(k),k]}]
      optional_keys = constraints.keys.select{|k| k.to_s[-1..-1] != '!'}

      # check each of the provided options
      opts.keys.each do |key|
        raise "unknown option: #{[prefix,key].compact.join(".")}" if !required_keys.include?(key) && !optional_keys.include?(key)
        
        ckey = required_keys[key] || key
        if constraints[ckey].is_a? Hash
          check_opts(constraints[ckey], opts[key] || {}, [prefix,key].compact.join("."))
        end

        required_keys.delete(key)
        optional_keys.delete(key)
      end

      raise "required options not given: #{required_keys.keys.map{|k| [prefix,k].compact.join('.')}.join(", ")}" if required_keys.size>0
      
      # defaults
      optional_keys.each{|k| opts[k] = constraints[k] if !constraints[k].is_a?(Hash)}
      opts
    end

    def strip_bang(k)
      if k.is_a? Symbol
        k.to_s[0...-1].to_sym
      else
        k.to_s[0...-1]
      end
    end
  end
end
