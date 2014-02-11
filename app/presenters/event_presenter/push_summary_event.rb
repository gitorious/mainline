#--
#   Copyright (C) 2012-2014 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

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
      link = commit_link(h("#{title}:#{branch}"))
      action_for_event(:event_pushed, :link => link)
    end

    def category
      'push'
    end

    def body
      view.content_tag(:ul, :class => 'gts-event-commit-list') {
        inner_html = commits.map { |commit| render_commit(commit) }

        if commit_count >= COMMIT_LIMIT
          inner_html << content_tag(:li, :class => 'gts-view-all-commits') {
            link_to("View all #{commit_count} commits &raquo;".html_safe, diff_url)
          }
        end

        inner_html.join("\n").html_safe
      }
    end

    def render_commit(commit, options = {})
      user    = commit.committer_user
      message = format_summary(commit.title)

      link = link_to(
        view.content_tag('code', commit.short_oid).html_safe,
        view.project_repository_commit_url(project, repository, commit.id)
      )

      content =
        if user
          user_presenter = UserPresenter.new(user, view)
          "#{user_presenter.avatar_link} #{link} #{message}"
        else
          "#{commit.actor_display} #{link} #{message}"
        end

      view.content_tag(:li, content.html_safe, options)
    end

    def title
      repo_title(repository, project)
    end

    def commit_link(title)
      url = view.project_repository_commits_in_ref_url(
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
      if commit_count > 1
        view.project_repository_commit_compare_url(
          project, repository, :from_id => first_sha, :id => last_sha
        )
      else
        view.project_repository_commit_url(project, repository, last_sha)
      end
    end

    def repository
      target
    end

    def project
      repository.project
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

    def format_summary(summary)
      if summary.present?
        CGI.escapeHTML(summary)
      else
        "(empty commit message)"
      end
    end
  end

end
