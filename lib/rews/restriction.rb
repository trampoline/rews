# takes restrictions written in Ruby s-expressions and 
# outputs Exchange Web Services Restriction XML
#
#
module Rews
  class Restriction

    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def inspect
      "#{self.class}: #{@expr.inspect}"
    end

    def to_xml
      Xml::write_restriction(expr)
    end

    module Xml
      module_function

      def write_restriction(expr)
        xml = Builder::XmlMarkup.new
        xml.wsdl :Restriction do
          write_expr(xml, expr)
        end
        xml.target!
      end

      def write_expr(xml, expr)
        case expr[0]
        when :<, :<=, :==, :>=, :>, :"!=" then
          write_comparison(xml, expr)
        when :and, :or, :not then
          write_logical(xml, expr)
        else
          raise "unknown operator: #{expr[0]}"
        end
      end

      COMPARISON_OPS = {
        :< => :IsLessThan,
        :<= => :IsLessThanOrEqualTo,
        :== => :IsEqualTo,
        :>= => :IsGreaterThanOrEqualTo,
        :> => :IsGreaterThan,
        :"!=" => :IsNotEqualTo}
      
      def write_comparison(xml, expr)
        xml.t COMPARISON_OPS[expr[0]] do
          write_field_uri(xml, expr[1])
          write_field_uri_or_constant(xml, expr[2])
        end
      end

      def write_field_uri_or_constant(xml, expr)
        xml.t :FieldURIOrConstant do
          if expr.is_a?(Array) && expr[0] == :field_uri
            write_field_uri(xml, expr[1])
          else
            write_constant(xml, expr)
          end
        end
      end

      def write_field_uri(xml, expr)
        xml.t :FieldURI, :FieldURI=>expr
      end

      def write_constant(xml, expr)
        xml.t :Constant, :Value=>expr
      end

      LOGICAL_OPS = {
        :and => :And,
        :or => :Or,
        :not => :Not
      }
      def write_logical(xml, expr)
        xml.t LOGICAL_OPS[expr[0]] do
          expr[1..-1].each do |clause|
            Xml::write_expr(xml, clause)
          end
        end
      end
    end
  end
end
