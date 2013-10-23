class EventPresenter

  class CreateBranchEvent < self

    def action
      project = target.project

      if data == "master"
        action_for_event(:event_status_started) {
          "of " + view.link_to(h(project.slug), view.project_path(project)) + "/" +
          view.link_to(h(target.name), view.project_repository_url(project, target))
        }
      else
        action_for_event(:event_branch_created) do
          view.link_to(view.ref(data),
            view.project_repository_commits_in_ref_path(project, target, view.ensplat_path(data))) +
          " on " + view.link_to(h(project.slug), view.project_path(project)) + "/" +
          view.link_to(h(target.name),
            view.project_repository_url(project, target))
        end
      end
    end

    def body
      if data == 'master'
        h(body)
      else
        ''
      end
    end

    def category
      'commit'
    end

  end

end
