class EventPresenter

  class UpdateRepositoryEvent < self

    def action
      action_for_event(:event_updated_repository) {
        if repository
          link_to(
            h(repository.url_path),
            view.project_repository_path(project, repository)
          )
        else
          'repository was deleted'
        end
      }
    end

    def category
      'repository'
    end

    def repository
      target
    end

  end

end
