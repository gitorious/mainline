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

module Gitorious
  module MaxDepth
    def maxdepth
      3
    end
  end

  module DoltUrls
    def tree_url(repository, ref, path = "")
      "/#{repository}/trees/#{ref}/#{path}"
    end

    def blob_url(repository, ref, path)
      "/#{repository}/blobs/#{ref}/#{path}"
    end

    def blame_url(repository, ref, path)
      "/#{repository}/blobs/blame/#{ref}/#{path}"
    end

    def history_url(repository, ref, path)
      "/#{repository}/blobs/history/#{ref}/#{path}"
    end

    def raw_url(repository, ref, path)
      "/#{repository}/blobs/raw/#{ref}/#{path}"
    end

    def tree_history_url(repository, ref, path)
      "/TODO"
    end
  end

  class Dolt
    def initialize(repository)
      @repository = repository
      resolver = ::Dolt::GitoriousRepoResolver.new(@repository)
      @actions = ::Dolt::RepoActions.new(resolver)
    end

    def tree(ref, path, &block)
      in_reactor do
        name = "#{@repository.project.slug}/#{@repository.name}"
        @actions.tree(name, ref, path.join("/"), &block)
      end
    end

    def blob(ref, path, &block)
      in_reactor do
        name = "#{@repository.project.slug}/#{@repository.name}"
        @actions.blob(name, ref, path.join("/"), &block)
      end
    end

    def self.view
      @view ||= create_view
    end

    def self.create_view
      view = Tiltout.new(::Dolt.template_dir, { :layout => nil })
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
