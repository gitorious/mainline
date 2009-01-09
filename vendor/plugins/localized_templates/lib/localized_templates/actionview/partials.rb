module ActionView
  class Base

    private
      def render_partial(options = {}) #:nodoc:
        local_assigns = options[:locals] || {}

        case partial_path = options[:partial]
        when String, Symbol, NilClass
          if options.has_key?(:collection)
            render_partial_collection(options)
          else
            _pick_partial_template(partial_path, I18n.locale).render_partial(self, options[:object], local_assigns)
          end
        when ActionView::Helpers::FormBuilder
          builder_partial_path = partial_path.class.to_s.demodulize.underscore.sub(/_builder$/, '')
          local_assigns.merge!(builder_partial_path.to_sym => partial_path)
          render_partial(:partial => builder_partial_path, :object => options[:object], :locals => local_assigns)
        when Array, ActiveRecord::Associations::AssociationCollection, ActiveRecord::NamedScope::Scope
          render_partial_collection(options.except(:partial).merge(:collection => partial_path))
        else
          object = partial_path
          render_partial(
            :partial => ActionController::RecordIdentifier.partial_path(object, controller.class.controller_path),
            :object => object,
            :locals => local_assigns
          )
        end
      end

      def render_partial_collection(options = {}) #:nodoc:
        return nil if options[:collection].blank?

        partial = options[:partial]
        spacer = options[:spacer_template] ? render(:partial => options[:spacer_template]) : ''
        local_assigns = options[:locals] ? options[:locals].clone : {}
        as = options[:as]

        index = 0
        options[:collection].map do |object|
          _partial_path ||= partial ||
            ActionController::RecordIdentifier.partial_path(object, controller.class.controller_path)
          template = _pick_partial_template(_partial_path, I18n.locale)
          local_assigns[template.counter_name] = index
          result = template.render_partial(self, object, local_assigns.dup, as)
          index += 1
          result
        end.join(spacer)
      end

      def _pick_partial_template(partial_path, locale = nil) #:nodoc:
        if partial_path.include?('/')
          path = File.join(File.dirname(partial_path), "_#{File.basename(partial_path)}")
        elsif controller
          path = "#{controller.class.controller_path}/_#{partial_path}"
        else
          path = "_#{partial_path}"
        end

        _pick_template(path, locale)
      end
      memoize :_pick_partial_template

  end
end