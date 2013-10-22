class EventPresenter < SimpleDelegator

  class RemoveCommitterEvent < self

    def action
      action_for_event(:event_committer_removed, :collaborator => h(data)) {
        " from " + view.link_to(repo_title(target, project), [project, target]) }
    end

    def category
      'repository'
    end

    def body
      ''
    end

  end

end
