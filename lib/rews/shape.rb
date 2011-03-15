module Rews
  module Shape

    module Xml
      module_function

      def write_shape(shape_type, &proc)
        xml = Builder::XmlMarkup.new
        xml.wsdl shape_type do
          proc.call(xml)
        end
        xml.target!
      end

      def write_additional_properties(xml, additional_properties)
        return if !additional_properties
        xml.t :AdditionalProperties do
          additional_properties.each do |additional_property|
            if additional_property[0] == :field_uri
              xml.t :FieldURI, :FieldURI=>additional_property[1]
            end
          end
        end
      end
    end

    class Base
      include Util
      attr_reader :shape

      def inspect
        "#<#{self.class} @shape=#{@shape}>"
      end
    end

    ITEM_SHAPE_OPTS = {
      :base_shape=>:Default,
      :include_mime_content=>nil,
      :additional_properties=>nil
    }

    class ItemShape < Base
      def initialize(shape)
        @shape = check_opts(ITEM_SHAPE_OPTS, shape)
      end

      def to_xml
        Xml::write_shape(:ItemShape) do |xml|
          xml.t :BaseShape, shape[:base_shape]
          xml.t :IncludeMimeContent, shape[:include_mime_content] if shape[:include_mime_content]
          Xml::write_additional_properties(xml, shape[:additional_properties])
        end
      end
    end

    FOLDER_SHAPE_OPTS = {
      :base_shape=>:Default,
      :additional_properties=>nil
    }

    class FolderShape < Base
      def initialize(shape)
        @shape = check_opts(FOLDER_SHAPE_OPTS, shape)
      end

      def to_xml
        Xml::write_shape(:FolderShape) do |xml|
          xml.t :BaseShape, shape[:base_shape]
          Xml::write_additional_properties(xml, shape[:additional_properties])
        end
      end
    end
  end
end
