class EventPresenter

  class PushEvent < PushSummaryEvent

    def action
      action_for_event(:event_pushed, :link => repository_link)
    end

    def body
      if commits
        super
      else
        ''
      end
    end

    def repository_link
      link_to("#{repo_title(repository, project)}", [project, repository])
    end

    def commit_count
      events.size
    end

    def repository
      target
    end

    private

    def initialize_commits
      super if events.size > 0
    end

    def initialize_event_data
      @event_data = {
        :start_sha    => events.first && events.first.data,
        :end_sha      => events.last && events.last.data,
        :commit_count => events.size,
        :branch       => data
      }
    end

  end

end
