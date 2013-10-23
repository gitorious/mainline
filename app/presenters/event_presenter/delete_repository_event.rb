class EventPresenter

  class DeleteRepositoryEvent < self

    def action
      action_for_event(:event_status_deleted) do
        link_to(h(target.title), target) + "/" + h(event.data)
      end
    end

    def body
      ''
    end

    def category
      'project'
    end

  end

end
