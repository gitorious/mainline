class EventPresenter < SimpleDelegator

  class PushSummaryEvent < self
    attr_reader :data
    private :data

    def initialize(*)
      super
      @data = PushEventLogger.parse_event_data(event.data)
    end

    def action
      link_foo = commit_link(pluralize(commit_count, 'commit'))
      link_bar = commit_link(h("#{title}:#{branch}"))

      action_for_event(:event_pushed_n, :commit_link => link_foo) {
        splits = ['to', link_bar]
        splits << link_to('View diff', diff_url) if diff_url
        splits.join(' ')
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

      options = {
        'gts:url' => commit_detail_url,
        'gts:id' => event.to_param
      }

      link_to(title, url, options)
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

    def commit_detail_url
      view.commits_event_path(event.to_param)
    end

    def repository
      target
    end

  end

end
