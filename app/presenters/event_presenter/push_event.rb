class EventPresenter < SimpleDelegator

  class PushEvent < self

    def render_event_push(event)
      event.single_commit? ? render_single_commit_push(event) : render_several_commit_push(event)
    end

    def render_single_commit_push(event)
      project = event.target.project
      commit = event.events.first
      repo = event.target
      commit_link = link_to(commit.data[0,8],
        project_repository_commit_path(project, repo, commit.data)
        )
      repo_link = link_to("#{repo_title(repo, project)}:#{event.data}",
        [project, repo])
      action = action_for_event(:event_pushed_n, :commit_link => commit_link) do
        "to #{repo_link}"
      end
      [action,"","push"]
    end

    def render_several_commit_push(event)
      commit_detail_url = commits_event_path(event.to_param)
      commit_count = event.events.size
      repository = event.target
      branch_name = event.data
      event_id = event.to_param
      message = event.body
      push_summary(commit_detail_url, commit_count, repository, branch_name, event_id, message)
    end


  end

end
