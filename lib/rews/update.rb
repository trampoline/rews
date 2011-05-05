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
          xml << Util.rsxml_to_xml(item_expr)
        end
        xml.target!
      end

      def update_tag(type)
        # final component of module scoped classname
        type.to_s[/(?:^|::)([^:]+)$/, 1].to_sym
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
