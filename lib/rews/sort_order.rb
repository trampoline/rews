# takes sort_orders written in Ruby s-expressions and
# outputs EWS SortOrder XML
module Rews
  class SortOrder
    attr_reader :expr

    def initialize(expr)
      @expr=expr
    end

    def inspect
      "#{self.class}: #{@expr.inspect}"
    end
    
    def to_xml
      Xml::write_sort_order(expr)
    end

    module Xml
      module_function

      def write_sort_order(expr)
        xml = Builder::XmlMarkup.new
        xml.wsdl :SortOrder do
          write_expr(xml, expr)
        end
        xml.target!
      end

      def write_expr(xml, expr)
        expr.each do |field_order|
          write_field_order(xml, field_order)
        end
      end

      def write_field_order(xml, field_order)
        if field_order.is_a?(Array)
          xml.t :FieldOrder, :Order=>field_order[1] do
            write_field_uri(xml, field_order[0])
          end
        else
          xml.t :FieldOrder, field_order do
            write_field_uri(xml, field_order)
          end
        end
      end

      def write_field_uri(xml, field_uri)
        xml.t :FieldURI, :FieldURI=>field_uri
      end
    end
  end
end
