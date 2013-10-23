class EventPresenter

  class AddCommitterEvent < self

    def action
      repo = event.target.is_a?(Repository) ? event.target : event.target.repository

      action_for_event(:event_committer_added, :collaborator => h(event.data)) {
        " to " +
        view.link_to(view.repo_title(repo, project), [project, repo])
      }
    end

    def category
      'repository'
    end

    def body
      ''
    end


  end

end
