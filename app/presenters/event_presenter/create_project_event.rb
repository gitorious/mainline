class EventPresenter < SimpleDelegator

  class CreateProjectEvent < self

    def action
      action_for_event(:event_status_created) {
        view.link_to(h(event.target.title), view.project_path(event.target))
      }
    end

    def body
      view.truncate(target.stripped_description, :length => 100)
    end

    def category
      'project'
    end

  end

end
