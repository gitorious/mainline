class EventPresenter

  class PushSummaryEvent < self
    COMMIT_LIMIT = 2

    attr_reader :event_data
    private :event_data

    attr_reader :commits

    def initialize(*)
      super
      initialize_event_data
      initialize_commits
    end

    def action
      link_title = commit_count > 1 ? "#{commit_count} commits" : "1 commit"
      diff_link = link_to(link_title, diff_url)
      action_for_event(:event_pushed_n, :commit_link => diff_link) {
        ['to', commit_link(h("#{title}:#{branch}"))].join(' ')
      }
    end

    def category
      'push'
    end

    def body
      view.content_tag(:ul, :class => 'gts-event-commit-list') {
        inner_html = commits.map { |commit| render_commit(commit) }

        if commit_count >= COMMIT_LIMIT
          inner_html << content_tag(:li) {
            link_to("View all &raquo;".html_safe, diff_url)
          }
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
      event_data[:start_sha]
    end

    def last_sha
      event_data[:end_sha]
    end

    def branch
      event_data[:branch]
    end

    def commit_count
      event_data[:commit_count].to_i
    end

    def diff_url
      view.project_repository_commit_compare_path(
        target.project, target, :from_id => first_sha, :id => last_sha
      )
    end

    def repository
      target
    end

    def initialize_event_data
      @event_data = PushEventLogger.parse_event_data(data)
    end

    def initialize_commits
      # FIXME: this won't be needed when we convert old push/commit events to
      #        push summary events
      first_commit = fetch_first_commit

      @commits =
        if first_commit
          [CommitPresenter.new(repository, first_commit)]
        else
          []
        end
    end

    def fetch_first_commit
      if commit_count > 1
        Rails.cache.fetch("push_summary_commits_#{id}") {
          begin
            walker = Rugged::Walker.new(Rugged::Repository.new(repository.full_repository_path))

            walker.push(last_sha)

            first_commit_sha = nil

            walker.each_with_index do |commit, index|
              if index == commit_count-1
                first_commit_sha = commit.oid
                break
              end
            end

            repository.git.commit(first_commit_sha)
          rescue Rugged::OdbError, Rugged::OSError, Rugged::InvalidError
            nil
          end
        }
      else
        repository.git.commit(last_sha)
      end
    end

    def visible_commits
      commits[0, COMMIT_LIMIT]
    end

    def hidden_commits
      Array(commits[COMMIT_LIMIT+1, commits.size]).compact
    end

  end

end
