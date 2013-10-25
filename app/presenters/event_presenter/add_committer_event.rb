class EventPresenter

  class AddCommitterEvent < self

    def action
      repo = event.target.is_a?(Repository) ? event.target : event.target.repository

      action_for_event(:event_committer_added, :collaborator => collaborator) {
        " to " +
        view.link_to(view.repo_title(repo, project), [project, repo])
      }
    end

    def category
      'repository'
    end

    private

    def collaborator
      h(data)
    end

  end

end
