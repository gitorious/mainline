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
  module MaxDepth
    def maxdepth
      3
    end
  end

  module DoltUrls
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

    def self.view
      @view ||= create_view
    end

    def self.create_view
      base = Pathname(__FILE__).dirname + "../../app/views/layouts/v3"
      layout = base.expand_path + "application.html.erb"
      puts "\n\n\n#{layout}\n\n\n"
      view = Tiltout.new(::Dolt.template_dir, { :layout => {:file => layout} })
      view.helper(Gitorious::DoltUrls)
      view.helper(::Dolt::View::Object)
      view.helper(::Dolt::View::Blob)
      view.helper(::Dolt::View::Blame)
      view.helper(::Dolt::View::Breadcrumb)
      view.helper(::Dolt::View::Tree)
      view.helper(::Dolt::View::Commit)
      view.helper(::Dolt::View::Gravatar)
      ::Dolt::View::TabWidth.tab_width = 4
      view.helper(::Dolt::View::TabWidth)
      view.helper(::Dolt::View::BinaryBlobEmbedder)
      view.helper(::Dolt::View::SmartBlobRenderer)
      view.helper(Gitorious::MaxDepth)
      view
    end

    def in_reactor(&block)
      if EventMachine.reactor_running?
        return block.call
      end

      EventMachine.run do
        block.call
        EventMachine.stop
      end
    end
  end
end
