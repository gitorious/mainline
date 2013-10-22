class EventPresenter < SimpleDelegator

  class PushSummaryEvent < self
    attr_reader :data
    private :data

    def initialize(*)
      super
      @data = PushEventLogger.parse_event_data(event.data)
    end

    def action
      diff_link = link_to("#{commit_count} commits", diff_url)
      action_for_event(:event_pushed_n, :commit_link => diff_link) {
        ['to', commit_link(h("#{title}:#{branch}"))].join(' ')
      }
    end

    def category
      'push'
    end

    def body
      "#{branch} changed from #{first_sha[0,7]} to #{last_sha[0,7]}"
    end

    def title
      repo_title(repository, project)
    end

    def commit_link(title)
      url = view.project_repository_commits_in_ref_path(
        repository.project, repository, ensplat_path(branch)
      )

      link_to(title, url)
    end

    def first_sha
      data[:start_sha]
    end

    def last_sha
      data[:end_sha]
    end

    def branch
      data[:branch]
    end

    def commit_count
      data[:commit_count]
    end

    def diff_url
      view.project_repository_commit_compare_path(
        target.project, target, :from_id => first_sha, :id => last_sha
      )
    end

    def repository
      target
    end

  end

end
