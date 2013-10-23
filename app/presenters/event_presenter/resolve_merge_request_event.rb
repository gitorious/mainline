class EventPresenter

  class ResolveMergeRequestEvent < self

    def render_event_resolve_merge_request(event)
      source_repository = event.target.source_repository
      project = source_repository.project
      target_repository = event.target.target_repository

      action_for_event(:event_resolved_merge_request) {
        link_to(h(target_repository.url_path) + " " + h("##{target.to_param}"),
          view.project_repository_merge_request_path(project, target_repository, target)) +
        " as " + "<em>#{state}</em>"
      }
    end

    def category
      'merge_request'
    end

    def body
      link_to(
        truncate(h(event.target.proposal), :length => 100),
        [project, target.target_repository, target]
      )
    end

    private

    def state
      data
    end

  end

end
