class EventPresenter

  class UpdateMergeRequestEvent < self

    def action
      source_repository = event.target.source_repository
      project = source_repository.project
      target_repository = event.target.target_repository

      action_for_event(:event_updated_merge_request) {
        link_to(h(target_repository.url_path) + " " + h("##{target.to_param}"),
          view.project_repository_merge_request_path(project, target_repository, target))
      }
    end

    def body
      "&#x2192; #{sanitize(state_change)}".html_safe
    end

    def category
      'merge_request'
    end

    private

    def state_change
      data
    end

  end

end
