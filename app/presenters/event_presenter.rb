class EventPresenter < SimpleDelegator
  attr_reader :view
  private :view

  alias_method :event, :__getobj__

  delegate :link_to, :h, :truncate, :dom_id, :pluralize, :ensplat_path,
    :repo_path, :repo_title, :sanitize, :content_tag, :to => :view

  def self.build(event, view)
    begin
      name  = "#{self.name}::#{event.action_name.split.join('_').classify}Event"
      klass = name.constantize
    rescue NameError => e
      Rails.logger.error "AAA: #{event.inspect}"
      Rails.logger.error "AAA: #{e.message}"
      klass = self
    end

    klass.new(event, view)
  end

  def initialize(event, view)
    super(event)
    @view = view
  end

  def action_for_event(key, options = {}, &block)
    header = I18n.t("application_helper.#{key}", options)
    [header, block.call].join(' ')
  end

end

Dir[Rails.root.join('app/presenters/event_presenter/*')].each do |file|
  require_dependency file
end
