module ActionController
  class Base

    private
      def layout_directory?(layout_name)
        @template.__send__(:_pick_template, "#{File.join('layouts', layout_name)}.#{@template.template_format}", I18n.locale) ? true : false
      rescue ActionView::MissingTemplate
        false
      end

  end
end