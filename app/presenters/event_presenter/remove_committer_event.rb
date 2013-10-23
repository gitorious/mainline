class EventPresenter

  class RemoveCommitterEvent < self

    def action
      action_for_event(:event_committer_removed, :collaborator => collaborator) {
        " from " + view.link_to(repo_title(target, project), [project, target]) }
    end

    def category
      'repository'
    end

    def body
      ''
    end

    private

    def collaborator
      h(data)
    end

  end

end
