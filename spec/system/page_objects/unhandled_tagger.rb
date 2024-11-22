module PageObjects
  module Pages
    class UnhandledTagger < PageObjects::Pages::Base
      def handle
        page.find(".topic-footer-main-buttons .handle").click
      end

      def unhandle
        page.find(".topic-footer-main-buttons .unhandle").click
      end

      def handled?
        page.has_css?(".topic-footer-main-buttons .unhandle")
        page.find(".discourse-tags").has_no_content?("unhandled")
      end

      def unhandled?
        page.has_css?(".topic-footer-main-buttons .handle")
        page.find(".discourse-tags").has_content?("unhandled")
      end

      def disabled?
        page.has_no_css?(".topic-footer-main-buttons .handle")
        page.has_no_css?(".topic-footer-main-buttons .unhandle")
      end
    end
  end
end
