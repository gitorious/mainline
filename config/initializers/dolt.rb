# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
require "libdolt"
require "tiltout"
require "eventmachine"
require "erubis"
require "pathname"

module Gitorious
  module DoltViewHelper
    include ::Dolt::View::Object
    include ::Dolt::View::Blob
    include ::Dolt::View::Blame
    include ::Dolt::View::Breadcrumb
    include ::Dolt::View::Tree
    include ::Dolt::View::Commit
    include ::Dolt::View::Gravatar
    include ::Dolt::View::TabWidth
    include ::Dolt::View::BinaryBlobEmbedder
    include ::Dolt::View::SmartBlobRenderer

    # How many directory levels do we want to expand? When browsing directories
    # deeper than the specified depth, the initial directories will be chunked
    # like so:
    #
    # lib/gitorious
    #   something
    #     really
    #       nested
    #
    def maxdepth
      3
    end

    # Dolt::View::TabWidth module converts tabs to spaces so we can control the
    # rendered width. This number specifies the desired width.
    #
    def tabwidth
      4
    end

    def tree_url(repository, ref, path = "")
      "/#{repository}/source/#{ref}:#{path}"
    end

    def blob_url(repository, ref, path)
      "/#{repository}/source/#{ref}:#{path}"
    end

    def blame_url(repository, ref, path)
      "/#{repository}/blame/#{ref}:#{path}"
    end

    def history_url(repository, ref, path)
      "/#{repository}/history/#{ref}:#{path}"
    end

    def raw_url(repository, ref, path)
      "/#{repository}/raw/#{ref}:#{path}"
    end

    def tree_history_url(repository, ref, path)
      "/#{repository}/tree_history/#{ref}:#{path}"
    end

    def repo_nav_entries(repository, ref)
      [[:readme, "Readme", tree_url(repository, ref, "Readme")],
       [:activities, "Activities", "/activities"],
       [:commits, "Commits", "/commits"],
       [:source, "Source", "/source"],
       [:merge_requests, "Merge requests", "/merge-requests"],
       [:community, "Community", "/community"]]
    end

    def repo_nav(repository, ref, path, options)
      items = options[:entries].map do |entry|
        is_active = entry.first == options[:active]
        <<-HTML
          <li#{" class=\"active\"" if is_active}>
            <a#{" href=\"" + entry.last + "\"" if !is_active}>#{entry[1]}</a>
          </li>
        HTML
      end

      "<ul class=\"nav nav-tabs\">#{items.join}</ul>"
    end
  end

  module LayoutHelper
    def project_url(project)
      "/#{project.slug}"
    end

    def download_ref_url(repository, ref)
      "#"
    end

    def watch_repository_url(repository)
      "#"
    end

    def clone_repository_url(repository)
      "#"
    end

    def git_clone_url(repository)
      repository.git_clone_url
    end

    def http_clone_url(repository)
      repository.http_clone_url
    end

    def ssh_clone_url(repository)
      repository.ssh_clone_url
    end

    def git_cloning?(repository)
      repository.git_cloning?
    end

    def http_cloning?(repository)
      repository.http_cloning?
    end

    def ssh_cloning?(repository)
      repository.ssh_cloning?
    end

    def default_clone_url(repository)
      repository.default_clone_url
    end

    def repo_url_button(repository, options)
      type = options[:type].downcase
      return "" if !send(:"#{type}_cloning?", repository)
      url = send(:"#{type}_clone_url", repository)
      class_name = (options[:active] ? "active " : "") + "btn gts-repo-url"
      html = "<a class=\"#{class_name}\" href=\"#{url}\">#{options[:type]}</a>"
      return html unless options[:active]
      "#{html}<input class=\"span4 gts-current-repo-url gts-select-onfocus\" " +
        "type=\"url\" value=\"#{url}\">"
    end
  end

  class Dolt
    def initialize(project, repository)
      @project = project
      @repository = repository
      resolver = ::Dolt::GitoriousRepoResolver.new(@repository)
      @actions = ::Dolt::RepoActions.new(resolver)
    end

    def object(ref, path, &block)
      in_reactor do
        name = "#{@project.slug}/#{@repository.name}"
        @actions.tree_entry(name, ref, path, &block)
      end
    end

    def render(type, data)
      data[:project] = @project
      data[:repo] = @repository
      self.class.view.render(type, data)
    end

    def self.view
      @view ||= create_view(Pathname(__FILE__).dirname + "../../app/views/layouts/v3")
    end

    def self.create_view(base)
      Tiltout.new(::Dolt.template_dir, {
        :layout => { :file => base.expand_path + "application.html.erb" },
        :helpers => [Gitorious::DoltViewHelper, Gitorious::LayoutHelper],
        :cache => Rails.env != "development"
      })
    end

    def in_reactor(&block)
      return block.call if EventMachine.reactor_running?

      EventMachine.run do
        block.call
        EventMachine.stop
      end
    end
  end
end
