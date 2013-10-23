class EventPresenter

  class DeleteProjectEvent < self

    def action
      action_for_event(:event_status_deleted){ h(data) }
    end

    def body
      ''
    end

    def category
      'project'
    end

  end

end
