# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
require "gitorious/view"
require "gitorious/view/layout_helper"

# Dolt::View::TabWidth module converts tabs to spaces so we can control the
# rendered width. This number specifies the desired width.
#
Dolt::View::TabWidth.tab_width = 4

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
    include Gitorious::View::LayoutHelper

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
  end

  class Dolt
    def initialize(project, repository)
      @project = project
      @repository = repository
      resolver = ::Dolt::GitoriousRepoResolver.new(@repository)
      @actions = ::Dolt::RepoActions.new(resolver)
      @repo_name = "#{@project.slug}/#{@repository.name}"
    end

    def method_missing(name, *args, &block)
      return super if !@actions.respond_to?(name)
      @actions.send(name, @repo_name, *args, &block)
    end

    def render(type, data)
      data[:project] = @project
      data[:repo] = @repository
      self.class.view.render(type, data)
    end

    def self.view
      @view ||= create_view
    end

    def self.create_view
      Tiltout.new(::Dolt.template_dir, {
        :layout => { :file => Gitorious::View.layout_file },
        :helpers => [Gitorious::DoltViewHelper],
        :cache => Rails.env != "development"
      })
    end

    def self.in_reactor(&block)
      return block.call if EventMachine.reactor_running?

      EventMachine.run do
        block.call
        EventMachine.stop
      end
    end
  end
end
