class EventPresenter

  class PushSummaryEvent < self
    COMMIT_LIMIT = 3

    attr_reader :data
    private :data

    attr_reader :commits

    def initialize(*)
      super
      initialize_data
      initialize_commits
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
      view.content_tag(:ul, :class => 'gts-event-commit-list') {
        inner_html = visible_commits.map { |commit| render_commit(commit) }
        inner_html << hidden_commits.map { |commit| render_commit(commit, :class => 'hide') }

        if commits.size > COMMIT_LIMIT
          inner_html << content_tag(:li, link_to("View all &raquo;".html_safe, '#', :data => { :behavior => 'show-commits' }))
        end

        inner_html.join("\n").html_safe
      }
    end

    def render_commit(commit, options = {})
      user    = commit.committer_user
      message = commit.summary

      link = link_to(
        view.content_tag('code', commit.short_oid).html_safe,
        view.project_repository_commit_path(project, repository, commit.id)
      )

      content =
        if user
          "#{view.avatar(user, :size => 16, :class => 'gts-avatar')} #{link} #{message}"
        else
          "#{commit.actor_display} #{link} #{message}"
        end

      view.content_tag(:li, content.html_safe, options)
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

    private

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

    def initialize_data
      @data = PushEventLogger.parse_event_data(event.data)
    end

    def initialize_commits
      commits = Gitorious::Commit.load_commits_between(
        repository.git, first_sha, last_sha, id
      )

      @commits = commits.map { |commit| CommitPresenter.new(repository, commit.id) }
    end

    def visible_commits
      commits[0, COMMIT_LIMIT]
    end

    def hidden_commits
      Array(commits[COMMIT_LIMIT, commits.size]).compact
    end

  end

end
