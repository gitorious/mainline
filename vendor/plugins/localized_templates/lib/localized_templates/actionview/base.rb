module ActionView
  class Base
    @@exempt_from_layout = Set.new([/\.rjs$/])

    # Renders the template present at <tt>template_path</tt> (relative to the view_paths array).
    # The hash in <tt>local_assigns</tt> is made available as local variables.
    def render(options = {}, local_assigns = {}, &block) #:nodoc:
      local_assigns ||= {}

      if options.is_a?(String)
        ActiveSupport::Deprecation.warn(
          "Calling render with a string will render a partial from Rails 2.3. " +
          "Change this call to render(:file => '#{options}', :locals => locals_hash)."
        )

        render(:file => options, :locals => local_assigns)
      elsif options == :update
        update_page(&block)
      elsif options.is_a?(Hash)
        options = options.reverse_merge(:locals => {})
        if options[:layout]
          _render_with_layout(options, local_assigns, &block)
        elsif options[:file]
          _pick_template(options[:file], I18n.locale).render_template(self, options[:locals])
        elsif options[:partial]
          render_partial(options)
        elsif options[:inline]
          InlineTemplate.new(options[:inline], options[:type]).render(self, options[:locals])
        elsif options[:text]
          options[:text]
        end
      end
    end

    private
      def _pick_template(template_path, locale = nil)
        return template_path if template_path.respond_to?(:render)

        path = template_path.sub(/^\//, '')
        if m = path.match(/(.*)\.(\w+)$/)
          template_file_name, template_file_extension = m[1], m[2]
        else
          template_file_name = path
        end

        # Try to render locale/controller/action
        if locale && template = _template_view_path_check("#{locale}/#{template_file_name}")
          template
        # Try to render controller/action
        elsif template = _template_view_path_check(template_file_name)
          template
        else
          template = Template.new(template_path, view_paths)

          if self.class.warn_cache_misses && logger
            logger.debug "[PERFORMANCE] Rendering a template that was " +
              "not found in view path. Templates outside the view path are " +
              "not cached and result in expensive disk operations. Move this " +
              "file into #{view_paths.join(':')} or add the folder to your " +
              "view path list"
          end

          template
        end
      end
      memoize :_pick_template
      
      def _template_view_path_check(template_file_name)
        # OPTIMIZE: Checks to lookup template in view path
        if template = self.view_paths["#{template_file_name}.#{template_format}"]
          template
        elsif template = self.view_paths[template_file_name]
          template
        elsif (first_render = @_render_stack.first) && first_render.respond_to?(:format_and_extension) &&
            (template = self.view_paths["#{template_file_name}.#{first_render.format_and_extension}"])
          template
        elsif template_format == :js && template = self.view_paths["#{template_file_name}.html"]
          @template_format = :html
          template
        else
          nil
        end
      end

      def _exempt_from_layout?(template_path) #:nodoc:
        template = _pick_template(template_path, I18n.locale).to_s
        @@exempt_from_layout.any? { |ext| template =~ ext }
      rescue ActionView::MissingTemplate
        return false
      end

  end
end