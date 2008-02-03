module Gitorious
  module Diff
    class BaseCallback < ::Diff::Renderer::Base
      def headerline(line); end
      def new_line; end
      
      protected
        def escape(text)
          text.gsub('&', '&amp;').
            gsub('<', '&lt;').
            gsub('>', '&gt;').
            gsub('"', '&#34;')
        end
    end
  end
end