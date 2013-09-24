# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

module Gitorious
  module View
    module RepositoryHelper
      def remote_link(repository, backend, label, default_remote_url)
        return "" if backend.nil?
        url = backend.url(repository.gitdir)
        class_name = "btn gts-repo-url"
        class_name += " active" if url == default_remote_url
        "<a class=\"#{class_name}\" href=\"#{url}\">#{label}</a>".html_safe
      end

      def refname(ref)
        return ref unless ref.length == 40
        ref[0...7]
      end

      def remote_url_selection(app, repository)
        default_remote = app.default_remote_url(repository)
        <<-HTML.html_safe
        <div class="btn-group gts-repo-urls">
          #{remote_link(repository, app.ssh_daemon, "SSH", default_remote)}
          #{remote_link(repository, app.git_http, app.git_http.scheme.upcase, default_remote)}
          #{remote_link(repository, app.git_daemon, "Git", default_remote)}
          <input class="span4 gts-current-repo-url gts-select-onfocus" type="url" value="#{default_remote}">
          <button data-toggle="collapse" data-target="#repo-url-help" class="gts-repo-url-help btn">?</button>
        </div>
        HTML
      end

      def repo_action_buttons(app, repository, ref)
        tarball_link = !app.tarballable?(repository) ? "" : <<-HTML
          <a href="#{archive_url(repository.path_segment, ref, "tar.gz")}" class="btn gts-download" rel="tooltip" data-original-title="Download #{refname(ref)} as .tar.gz">
            <i class="icon icon-download"></i> Download
          </a>
        HTML

        <<-HTML.html_safe
          <div class="pull-right">
            #{tarball_link}
            <div class="gts-watch-repository-ph gts-placeholder"></div>
            <div class="gts-clone-repository-ph gts-placeholder"></div>
          </div>
        HTML
      end

      def clone_help(app, repository)
        default_remote = app.default_remote_url(repository)
        <<-HTML.html_safe
          <div class="alert alert-info span pull-right">
            <p>
              To <strong>clone</strong> this repository:
            </p>
            <pre class="prettyprint">git clone #{default_remote}</pre>
            <p>
              To <strong>push</strong> to this repository:
            </p>
            <pre class="prettyprint"># Add a new remote
git remote add origin #{default_remote}

# Push the master branch to the newly added origin, and configure
# this remote and branch as the default:
git push -u origin master

# From now on you can push master to the "origin" remote with:
git push</pre>
          </div>
        HTML
      end

      def repo_navigation(repository, ref, active = nil)
        project = repository.project
        navigation = header_navigation([
            [:source, url_for(File.join("/", project.to_param, repository.to_param, "source", "#{repository.head_candidate_name}:")), "Source code"],
            [:activities, activities_project_repository_path(project, repository), "Activities"],
            [:commits, project_repository_commits_in_ref_path(project, repository, ref), "Commits"],
            [:merge_requests, project_repository_merge_requests_path(project, repository), "Merge requests <span class=\"count\">(#{repository.open_merge_request_count})</span>"],
            [:community, url_for(File.join("/", project.to_param, repository.to_param, "community")), "Community"]
          ], :active => active)

        active_attr = active.nil? ? "" : " data-gts-active=\"#{active}\""
        <<-HTML.html_safe
          <ul class="nav nav-tabs gts-header-nav"#{active_attr}>
            #{navigation}
            <li class="gts-repository-admin-ph gts-placeholder"></li>
            <li class="gts-request-merge-ph gts-placeholder"></li>
          </ul>
        HTML
      end

      def repository_title(repository, header_level = 1)
        html = ""

        if !(parent = repository.parent).nil?
          html += <<-HTML
            <p class="gts-clone-source">
              <i title="Cloned from #{parent.slug}" class="icon icon-share-alt"></i>
              Cloned from
              <a href="#{project_path(parent.project)}">#{parent.project.slug}</a> /
              <a href="#{project_repository_path(parent.project, parent)}">#{parent.name}</a>
            </p>
          HTML
        end

        project = repository.project
        (html + <<-HTML).html_safe
          <h#{header_level} class="span">
            <a href="#{project_path(project)}">#{project.slug}</a> /
            <a class="gts-repository-name-ph" href="#{project_repository_path(project, repository)}">#{repository.name}</a>
          </h#{header_level}>
        HTML
      end
    end
  end
end
