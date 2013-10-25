class EventPresenter

  class DeleteRepositoryEvent < self

    def action
      action_for_event(:event_status_deleted) do
        link_to(h(target.title), target) + "/" + h(repository_name)
      end
    end

    def category
      'project'
    end

    private

    def repository_name
      data
    end

  end

end
