require 'set'

module Rews
  class Error < RuntimeError
  end

  module Util
    module_function

    def tag_exception(e, tags)
      tags.each do |k,v|
        mc = class << e ; self ; end
        mc.send(:define_method, k){v}
      end
    end

    # validates an options hash against a constraints hash
    # in the constraints hash :
    # * keys ending in ! indicate option is required
    # * keys not ending in ! indicate option is not required
    # * non-nil values provide defaults
    # * hash values provide constraints for sub-hashes
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
      optional_keys.each{|k| opts[k] = constraints[k] if constraints[k] && !constraints[k].is_a?(Hash)}
      opts
    end

    # strip a ! from the end of a +String+ or +Symbol+
    def strip_bang(k)
      if k.is_a? Symbol
        k.to_s[0...-1].to_sym
      else
        k.to_s[0...-1]
      end
    end

    # camel-case a +String+
    def camelize(s)
      if s.is_a?(Symbol)
        s.to_s.split('_').map(&:capitalize).join.to_sym
      else
        s.split('_').map(&:capitalize).join
      end
    end

    # camel-case the keys of a +Hash+
    def camel_keys(h)
      Hash[h.map{|k,v| [camelize(k.to_s), v]}]
    end

    # given an exploded qname, apply a given namespace and uri if the qname
    # has no namespace already
    def apply_namespace(qname, apply_prefix, apply_uri)
      local_part, prefix, uri = qname
      
      if !prefix
        prefix = apply_prefix
        uri = apply_uri
      end

      [local_part, prefix, uri].compact
    end

    # given an exploded qname, camelize the local_part
    def camelize_qname(qname)
      local_part, prefix, uri = qname
      [camelize(local_part), prefix, uri].compact
    end

    # convert rsxml to xml, transforming local_parts of QNames to CamelCase and prefixing with
    # the t: namespace prefix if no namespace is already applied
    def rsxml_to_xml(sexp)
      # visit the rsxml, prefix the element tags with "t" namespace prefix, and camelcase
      # all QName local_parts
      transform_visitor = Rsxml::Visitor::BuildRsxmlVisitor.new() do |context, element_name, attrs|
        t_element_name = camelize_qname(apply_namespace(element_name, "t", Rews::SCHEMA_TYPES))
        t_attrs = Hash[attrs.map{|attr_name,v| [camelize_qname(attr_name), v]}]
        [t_element_name, t_attrs]
      end

      xrsxml = Rsxml::Sexp.traverse(sexp, transform_visitor).sexp
      Rsxml.to_xml(xrsxml, :ns=>{"t"=>Rews::SCHEMA_TYPES, "wsdl"=>Rews::SCHEMA_MESSAGES})
    end

    # check the response codes of an Exchange Web Services request.
    # the supplied block makes a SOAP request, and the response is parsed
    # out and checked
    def with_error_check(client, *response_msg_keys)
      raise "no block" if !block_given?

      begin
        response = yield
        hash_response = response.to_hash
        statuses = hash_response.fetch_in(*response_msg_keys)
        
        if statuses.is_a?(Array)
          all_statuses = statuses
        else
          all_statuses = [statuses]
        end
        
        errors = all_statuses.map{|s| single_error_check(client, s)}.compact
      rescue Exception=>e
        Rews.log{|logger| logger.warn(e)}
        tag_exception(e, :savon_response=>response)
        raise e
      end

      raise Error.new(errors.join("\n")) if !errors.empty?
      statuses
    end

    # check the status of the response of a single part of a multi-part request
    def single_error_check(client, status)
      begin
        response_class = status[:response_class]
      rescue
        raise "no response_class found: #{status.inspect}" if !response_class
      end

      if status[:response_class] == "Error"
        return "#{status[:response_code]} - #{status[:message_text]}"
      elsif status[:response_class] == "Warning"
        Rews.log{|logger| logger.warn("#{status[:response_code]} - #{status[:message_text]}")}
      end
    end
  end
end
