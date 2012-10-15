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
      @resolver = ::Dolt::GitoriousRepoResolver.new(@repository)
      @actions = ::Dolt::RepoActions.new(@resolver)
      @repo_name = "#{@project.slug}/#{@repository.name}"
    end

    def self.available?
      return @available if defined?(@available)
      @available = true

      if EventMachine.reactor_running?
        @available = false
        $stderr.puts <<-WARN


WARNING: The default Dolt (source code browser) integration does not work
with evented web servers. Any attempt to access
/<project>/<repository>/{source,blame,history,raw,tree,history,refs,readme}
URLs will not work.

If you wish run Gitorious with an evented server (e.g. Thin), you will have
to run the async Sinatra application for Dolt next to it, and proxy requests
in a front-end like nginx.

To avoid this issue in development, make sure you are not using `script/server`
with thin - use passenger or mongrel (or even webrick) in stead.


WARN
      end

      @available
    end

    def available?
      self.class.available?
    end

    def method_missing(name, *args, &block)
      return super if !@actions.respond_to?(name)
      @actions.send(name, @repo_name, *args, &block)
    end

    def render(type, data, opts = {})
      data[:project] = @project
      data[:repository] = @repository
      self.class.view.render(type, data, opts)
    end

    def rev_parse_oid_sync(ref)
      @resolver.resolve.rev_parse_oid_sync(ref)
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
      result = nil
      # Manual blocking...
      # Without this, two requests may try to complete their work in the same
      # reactor loop, which does not work
      sleep 0.01 while EventMachine.reactor_running?

      EventMachine.run do
        block.call(Proc.new do |res|
                     result = res
                     EventMachine.stop
                   end)
      end
      result
    end
  end
end
