class EventPresenter

  class UpdateProjectEvent < self

    def action
      action_for_event(:event_status_updated) {
        link_to(h(event.target.title), view.project_path(event.target))
      }
    end

    def body
      ''
    end

    def category
      'project'
    end

  end

end
