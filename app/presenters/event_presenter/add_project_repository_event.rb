class EventPresenter < SimpleDelegator

  class AddProjectRepositoryEvent < self

    def action
      action_for_event(:event_status_add_project_repository) {
        link_to(h(target.name), view.project_repository_path(project, target)) +
                " in " + link_to(h(project.title), view.project_path(project))
      }
    end

    def category
      'repository'
    end

    def body
      truncate(sanitize(target.description, :tags => %w[a em i strong b]), :length => 100)
    end

  end


end
