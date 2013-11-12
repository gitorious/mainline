class EventPresenter

  class RequestMergeEvent < self

    def action
      source_repository = event.target.source_repository
      project = source_repository.project
      target_repository = event.target.target_repository

      action_for_event(:event_requested_merge_of) {
        link_to(repo_title(source_repository, project),
          [project, source_repository]) +
        " with " + link_to(h(target_repository.name),
          [project, target_repository]) +
        " in merge request " + link_to(h(target_repository.url_path) + " " + h("##{target.to_param}"),
          view.project_repository_merge_request_path(project, target_repository, target))
      }
    end

    def body
      link_to(
        truncate(h(target.summary), :length => 100),
        [project, target.target_repository, target]
      )
    end

    def category
      'merge_request'
    end


  end

end
