module Rews
  class Update
    attr_reader :field_uri
    attr_reader :item_expr

    def initialize(field_uri, item_expr=nil)
      @field_uri = field_uri
      @item_expr = item_expr
    end

    def inspect
      "#<#{Xml.update_tag(self.class)} @field_uri=#{@field_uri}, @item_expr=#{@item_expr.inspect}>"
    end

    def to_xml
      Xml.write_update(self.class, field_uri, item_expr)
    end

    module Xml
      module_function
      
      def write_update(type, field_uri, item_expr)
        xml = Builder::XmlMarkup.new
        xml.t(update_tag(type)) do
          xml.t :FieldURI, :FieldURI=>field_uri
          write_item_sexp(xml, item_expr)
        end
        xml.target!
      end

      def update_tag(type)
        # final component of module scoped classname
        type.to_s[/(?:^|::)([^:]+)$/, 1].to_sym
      end

      # writes an Item expression given as an s-expression hierarchy
      # [tag, attrs, body] e.g.
      # 
      # <tt> [:item, nil, [:response_objects, nil, [:suppress_read_receipt]]] </tt>
      def write_item_sexp(xml, sexp)
        return if !sexp
        
        if sexp.length<1
          raise "invalid Item sexp: #{sexp.inspect}"
        end

        tag, attrs, *children = sexp

        tag = Util.camelize(tag.to_s).to_sym
        attrs = Util.camel_keys(attrs||{})

        xml.t(tag, attrs) do
          children.each do |child|
            if child.is_a?(Array)
              write_item_sexp(xml, child)
            else
              xml << child
            end
          end
        end
      end
    end
  end

  class SetItemField < Update
  end

  class AppendToItemField < Update
  end

  class DeleteItemField < Update
  end
end
