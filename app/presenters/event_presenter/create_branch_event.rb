class EventPresenter

  class CreateBranchEvent < self

    def action
      project = target.project

      if master?
        action_for_event(:event_status_started) {
          [
            "of ",
            view.link_to(h(project.slug), view.project_path(project)),
            "/",
            view.link_to(h(target.name), view.project_repository_url(project, target))
          ].join
        }
      else
        action_for_event(:event_branch_created) do
          view.link_to(view.ref(branch),
            view.project_repository_commits_in_ref_path(project, target, view.ensplat_path(branch))) +
          " on " + view.link_to(h(project.slug), view.project_path(project)) + "/" +
          view.link_to(h(target.name),
            view.project_repository_url(project, target))
        end
      end
    end

    def body
      if master?
        h(event.body)
      else
        ''
      end
    end

    def category
      'commit'
    end

    private

    def branch
      data
    end

    def master?
      branch == 'master'
    end

  end

end
