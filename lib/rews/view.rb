module Rews
  # models +IndexedPageItemView+ and +IndexedPageFolderView+ definitions used by
  # <tt>Folder::BaseFolderId.find_*</tt> methods
  module View
    module Xml
      module_function

      def write_item_view(view_type, attrs, &proc)
        xml = Builder::XmlMarkup.new
        xml.wsdl view_type, Util::camel_keys(attrs) do
          proc.call(xml) if proc
        end
        xml.target!
      end
    end

    class Base
      include Util
      
      attr_reader :view

      def inspect
        "#<#{self.class} @view=#{@view.inspect}>"
      end
    end

    INDEXED_PAGE_VIEW_OPTS = {:max_entries_returned=>nil, :offset=>0, :base_point=>:Beginning}

    # models the +IndexedPageItemView+ used in <tt>Folder::BaseFolderId.find_item</tt> method
    class IndexedPageItemView < Base
      def initialize(view)
        @view = check_opts(INDEXED_PAGE_VIEW_OPTS, view)
      end

      def to_xml
        Xml::write_item_view(:IndexedPageItemView, view)
      end
    end

    # models the +IndexedPageFolderView+ used in <tt>Folder::BaseFolderId.find_folder</tt> methods
    class IndexedPageFolderView < Base
      def initialize(view)
        @view = check_opts(INDEXED_PAGE_VIEW_OPTS, view)
      end

      def to_xml
        Xml::write_item_view(:IndexedPageFolderView, view)
      end
    end
  end
end
