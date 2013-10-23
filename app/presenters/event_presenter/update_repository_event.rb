class EventPresenter

  class UpdateRepositoryEvent < self

    def action
      action_for_event(:event_updated_repository) {
        link_to(
          h(target.url_path),
          view.project_repository_path(target.project, event)
        )
      }
    end

    def category
      'repository'
    end

  end

end
