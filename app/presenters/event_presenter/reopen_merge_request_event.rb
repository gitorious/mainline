class EventPresenter < SimpleDelegator

  class ReopenMergeRequestEvent < self

    def action
      source_repository = event.target.source_repository
      project = source_repository.project

      action_for_event(:event_reopened_merge_request) {
        "in " +
        link_to(h(project.title), view.project_path(project)) + "/" +
        link_to(h(source_repository.name), view.project_repository_url(project, source_repository))
      }
    end

    def body
      link_to(
        truncate(h(event.target.proposal), :length => 100),
        [project, target_repository, event.target]
      )
    end

    def category
      'merge_request'
    end

  end

end
