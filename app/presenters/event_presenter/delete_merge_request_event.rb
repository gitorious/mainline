class EventPresenter < SimpleDelegator

  class DeleteMergeRequestEvent < self

    def action
      project = target.project

      action_for_event(:event_deleted_merge_request) {
        "from " + link_to(h(project.slug), view.project_path(project)) + "/" +
        link_to(h(target.name), view.project_repository_url(project, target))
      }
    end

    def category
      'merge_request'
    end

    def body
      ''
    end

  end

end
