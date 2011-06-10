# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

# Unsupported/deprecated actions:
#   COMMIT = 5
#   REOPEN_MERGE_REQUEST = 21

module EventRendering
  class UnknownActionError < StandardError; end

  class Text
    TEMPLATE_RE = /\{([^\}]+)\}/.freeze

    # renders the +event+ as a text-only representation
    def self.render(event)
      new(event).render
    end

    def initialize(event)
      @event = event
      @output = []
    end

    # adds +line+ to the output
    def add(line)
      @output << line
    end

    # renders the given +template+ to a string, replacing with
    # +values+. For example the template "Mr. {first} {last}"
    # becomes "Mr. John Smith"
    def template_to_str(template, values = {})
      template.gsub(TEMPLATE_RE) do
        values[$1.to_sym].to_s
      end
    end

    # render the given +template+, replacing with +values+ and adds it
    # directly to the output buffer
    def add_from_template(template, values)
      add(template_to_str(template, values))
    end

    def render
      case @event.action
      when Action::CLONE_REPOSITORY
        render_clone_repo
      when Action::DELETE_REPOSITORY
        render_delete_repo
      when Action::CREATE_BRANCH
        render_branch(:created)
      when Action::DELETE_BRANCH
        render_branch(:deleted)
      when Action::CREATE_TAG
        render_tag(:created)
      when Action::DELETE_TAG
        render_tag(:deleted)
      when Action::ADD_COMMITTER
        render_collaborator(:added)
      when Action::REMOVE_COMMITTER
        render_collaborator(:removed)
      when Action::COMMENT
        render_comment
      when Action::REQUEST_MERGE
        render_merge_request(:requested)
      when Action::RESOLVE_MERGE_REQUEST
        render_merge_request(:resolved)
      when Action::UPDATE_MERGE_REQUEST
        render_merge_request(:updated)
      when Action::DELETE_MERGE_REQUEST
        render_merge_request_deletion
      when Action::PUSH
        render_push
      when Action::CREATE_PROJECT
        render_project(:created)
      when Action::DELETE_PROJECT
        render_project(:deleted)
      when Action::UPDATE_PROJECT
        render_project(:updated)
      when Action::UPDATE_WIKI_PAGE
        render_update_wiki_page
      when Action::ADD_PROJECT_REPOSITORY
        render_added_project_repository
      when Action::UPDATE_REPOSITORY
        render_update_repository
      when Action::ADD_FAVORITE
        render_added_favorite
      when Action::PUSH_SUMMARY
        render_push_summary
      else
        raise EventRendering::UnknownActionError, "unknown action: #{@event.action.inspect}"
      end

      add("\n" + url(@event.project.slug)) if @event.project and !skip_project_link?

      @output.join("\n")
    end

    # We don't want to include project link unless this makes sense
    # skip_project_link! to avoid this
    def skip_project_link?
      @skip_project_link
    end

    def skip_project_link!
      @skip_project_link = true
    end

    def render_clone_repo
      source = Repository.find(@event.data)
      add_from_template("{user} cloned {source} {target}", {
        :user => @event.target.user.login,
        :source => source.url_path,
        :target => url(@event.target.url_path)
      })
    end

    def render_delete_repo
      add_from_template("{user} deleted repository {name}", {
          :user => @event.target.login,
          :name => @event.data
        })
    end

    def render_branch(action)
      add_from_template("{user} {action} branch {name} in {repo}", {
          :user => @event.user.login,
          :action => action,
          :name => @event.data,
          :repo => url(@event.target.url_path)
        })
    end

    def render_merge_request(action)
      summary = (action == :requested) ? "requested a merge of" : "#{action} merge request for"
      merge_request = @event.target
      skip_project_link!
      add_from_template("{user} #{summary} {source} with {target}.\nThe merge request is at {url}",
        :user => @event.user.login,
        :source => @event.target.source_repository.name,
        :url => url(merge_request.target_repository.url_path, "merge_requests", @event.target.to_param),
        :target => @event.target.target_repository.name)
    end

    def render_merge_request_deletion
      summary = "deleted merge request for"
      add_from_template("{user} #{summary} {source} with {target}.",
        :user => @event.user.login,
        :source => @event.target.source_repository.name,
        :target => @event.target.target_repository.name)
    end

    def render_tag(action)
      line = template_to_str("{user} {action} tag {name} in {repo}", {
          :user => @event.user.login,
          :action => action,
          :name => @event.data,
          :repo => url(@event.target.url_path)
        })
      line += ":\n#{@event.body}" unless @event.body.blank?

      add(line)
    end

    def render_collaborator(action)
      direction = action == :added ? "to" : "from"
      add_from_template("{user} {action} {collaborator} as collaborator " +
        "#{direction} {repo}", {
          :user => @event.user.login,
          :action => action,
          :collaborator => @event.data,
          :repo => url(@event.target.url_path)
        })
    end

    def render_comment
      comment = Comment.find(@event.data) # FIXME: sucks
      template_string = "{user} commented on {url}:\n{body}"
      if @event.body == "MergeRequest"
        repo = @event.target.target_repository
        add_from_template(template_string, {
            :user =>  @event.user.login,
            :url => url(repo.url_path, "merge_requests", @event.target.to_param),
            :body => comment.body
          })
      else
        repo = @event.target
        add_from_template(template_string, {
            :user =>  @event.user.login,
            :url => url(repo.url_path, "commit", comment.sha1),
            :body => comment.body
          })
      end
    end

    def render_push
      commits = @event.events.commits.map do |commit|
        "#{commit.actor_display} committed #{commit.data[0,6]}:\n" +
          "#{commit.body}\n" +
          url(@event.target.url_path, "commit", commit.data)
      end
      add_from_template("{user} pushed {count} commits to {branch}\n" +
        "{ref_change}\n\n{commits}", {
          :user => @event.user.login,
          :count => @event.events.commits.count,
          :branch => @event.data,
          :ref_change => @event.body,
          :commits => commits.join("\n\n")
        })
    end


    def render_push_summary
      event_data = PushEventLogger.parse_event_data(@event.data)
      url = "#{GitoriousConfig['scheme']}://#{GitoriousConfig['gitorious_host']}/#{@event.project.slug}/#{@event.target.name}/commits"
      branch_name = event_data[:branch]
      start_sha = event_data[:start_sha_short]
      end_sha = event_data[:end_sha_short]
      add_from_template("{user} pushed {commit_count} commits to {branch}\n{changes}\n\nView the commit log at {url}",
        {
          :user => @event.user.login,
          :count => event_data[:commit_count],
          :branch => branch_name,
          :changes => "#{branch_name} changed from #{start_sha} to #{end_sha}",
          :url => url,
          :commit_count => event_data[:commit_count]
        })      
    end

    def render_project(action)
      add_from_template("{user} {action} project {name}", {
          :user => @event.user.login,
          :action => action,
          :name => (action == :deleted ? @event.body : @event.target.title)
        })
      add(@event.target.description) if action == :created
    end

    def render_update_wiki_page
      add_from_template("{user} updated wiki page {name}\n{link}", {
          :user => @event.user.login,
          :name => @event.data,
          :link => url(@event.target.slug, "pages", @event.data)
        })
    end

    def render_added_project_repository
      description = @event.target.description.blank? ? "" : @event.target.description + "\n"
      add_from_template("{user} added a repository to {project}\n{description}{url}", {
          :user => @event.user.login,
          :project => @event.target.project.title,
          :description => description,
          :url => url(@event.target.url_path)
        })
    end

    def render_update_repository
      add_from_template("{user} updated {repo_path}{body}", {
          :user => @event.user.login,
          :repo_path => @event.target.url_path,
          :body => (@event.body.blank? ? "" : "\n" + @event.body)
        })
    end

    def render_added_favorite
      watchable_class = @event.body.constantize
      watchable = watchable_class.find(@event.data)

      case watchable
      when Repository
        add_from_template("{user} favorited {repo}\n{link}", {
            :user => @event.user.login,
            :repo => watchable.url_path,
            :link => url(watchable.url_path)
          })
      when MergeRequest
        add_from_template("{user} favorited merge request \#{seq} " +
          "in {repo}:\n{title}\n{link}", {
            :user => @event.user.login,
            :seq => watchable.sequence_number,
            :repo => watchable.target_repository.url_path,
            :title => watchable.summary,
            :link => url(watchable.target_repository.url_path,
                         "merge_requests", watchable.sequence_number.to_s)
          })
      end
    end

    protected
    def base_url
      "http://" + GitoriousConfig["gitorious_host"]
    end

    def url(*parts)
      File.join(base_url, *parts)
    end
  end
end
