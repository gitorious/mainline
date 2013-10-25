class EventPresenter

  class DeleteProjectEvent < self

    def action
      action_for_event(:event_status_deleted){ h(project_name) }
    end

    def category
      'project'
    end

    private

    def project_name
      data
    end

  end

end
