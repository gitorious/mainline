class EventPresenter
  attr_reader :event, :view
  private :event, :view

  delegate :link_to, :h, :truncate, :dom_id, :pluralize, :ensplat_path,
    :repo_path, :repo_title, :sanitize, :content_tag, :to => :view

  def self.build(event, view)
    name  = "#{self.name}::#{event.action_name.split.join('_').classify}Event"
    klass = name.constantize
    klass.new(event, view)
  end

  def initialize(event, view)
    @event = event
    @view  = view
  end

  def actor
    user.fullname? ? user.fullname : user.login
  end

  def has_avatar?
    user && user.avatar
  end

  def body
    ''
  end

  private

  def action_for_event(key, options = {}, &block)
    header = I18n.t("application_helper.#{key}", options)
    [header, block.call].join(' ')
  end

  def method_missing(name, *args, &block)
    if event.respond_to?(name)
      event.public_send(name, *args, &block)
    else
      super
    end
  end

end

Dir[Rails.root.join('app/presenters/event_presenter/*')].each do |file|
  require_dependency file
end
