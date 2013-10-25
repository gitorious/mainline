class EventPresenter

  class DeleteTagEvent < self

    def action
      action_for_event(:event_tag_deleted) {
        h(tag_name) + " on " +
        view.link_to(h(project.slug), view.project_path(project)) +
        "/" +
        view.link_to(h(target.name), view.project_repository_url(project, target))
      }
    end

    def category
      'commit'
    end

    private

    def tag_name
      data
    end

  end

end
