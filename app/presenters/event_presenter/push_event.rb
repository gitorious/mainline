class EventPresenter

  class PushEvent < PushSummaryEvent
    COMMIT_LIMIT = 3

    def action
      if single_commit?
        commit = events.first

        commit_link = link_to(
          commit.data[0,8],
          view.project_repository_commit_path(project, repository, commit.data)
        )
      else
        commit_link = link_to("#{commit_count} commits", diff_url)
      end

      action_for_event(:event_pushed_n, :commit_link => commit_link) { "to #{repository_link}" }
    end

    def repository_link
      link_to("#{repo_title(repository, project)}:#{data}", [project, repository])
    end

    def commit_count
      events.size
    end

    def repository
      target
    end

    private

    def initialize_event_data
      @event_data = {
        :start_sha    => events.first.data,
        :end_sha      => events.last.data,
        :commit_count => events.size,
        :branch       => data
      }
    end

  end

end
