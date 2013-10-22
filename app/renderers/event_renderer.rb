class EventRenderer
  attr_reader :event, :view
  private :event, :view

  def initialize(event, view)
    @event, @view = event, view
  end

  def call
    view.render(partial_path, locals)
  end

  def partial_path
    "events/event"
  end

  def locals
    { :event => event }
  end
end
