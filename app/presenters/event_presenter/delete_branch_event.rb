class EventPresenter

  class DeleteBranchEvent < self

    def action
      project = event.target.project

      action_for_event(:event_branch_deleted) {
        view.ref(branch)  + ' on ' +
        view.link_to(h(project.slug), view.project_path(project)) +
        "/" + view.link_to(h(target.name),
                view.project_repository_url(project, target))
      }
    end

    def category
      'commit'
    end

    private

    def branch
      data
    end

  end

end
