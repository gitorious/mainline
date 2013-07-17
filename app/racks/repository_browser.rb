# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS and/or its subsidiary(-ies)
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
require "sinatra/base"
require "dolt/sinatra/actions"
require "libdolt/view/multi_repository"
require "gitorious/view/dolt_url_helper"

module Gitorious
  class RepositoryBrowser < ::Sinatra::Base
    include ::Dolt::View::MultiRepository
    include Gitorious::View::DoltUrlHelper
    include Gitorious::View::SiteHelper

    def initialize(lookup, renderer)
      @lookup = lookup
      @renderer = renderer
      super()
    end

    if !Rails.env.production? && RUBY_VERSION > "1.9"
      require "better_errors"
      use BetterErrors::Middleware
      BetterErrors.application_root = Rails.root.to_s
    end

    def self.instance; @instance; end
    def self.instance=(instance); @instance = instance; end

    # Implementing this method and returning true means that
    # Dolt will redirect any requests to refs to the actual commit
    # oid, e.g.:
    #   GET /gitorious/mainline/source/master:
    #   -> 302 /gitorious/mainline/source/2d4e282d02f438043fc425cc99a781774d22561a:
    def redirect_refs?; true; end

    get "/*/source/*:*" do
      repo, ref, path = params[:splat]
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.tree_entry(repo, ref, path, env_data)
      end
    end

    get "/*/source/*" do
      safe_action(params[:splat].first) do
        force_ref(params[:splat][0], params[:splat][1], "source")
      end
    end

    get "/*/raw/*:*" do
      repo, ref, path = params[:splat]
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.raw(repo, ref, path, env_data)
      end
    end

    get "/*/raw/*" do
      safe_action(params[:splat].first) do
        force_ref(params[:splat][0], params[:splat][1], "raw")
      end
    end

    get "/*/blame/*:*" do
      repo, ref, path = params[:splat]
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.blame(repo, ref, path, env_data)
      end
    end

    get "/*/blame/*" do
      safe_action(params[:splat].first) do
        force_ref(params[:splat][0], params[:splat][1], "blame")
      end
    end

    get "/*/history/*:*" do
      repo, ref, path = params[:splat]
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.history(repo, ref, path, (params[:commit_count] || 20).to_i, env_data)
      end
    end

    get "/*/history/*" do
      safe_action(params[:splat].first) do
        force_ref(params[:splat][0], params[:splat][1], "history")
      end
    end

    get "/*/refs" do
      repo = params[:splat].first
      safe_action(repo) do
        configure_env(repo)
        dolt.refs(repo, env_data)
      end
    end

    get "/*/tree_history/*:*" do
      repo, ref, path = params[:splat]
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.tree_history(repo, ref, path, 1, env_data)
      end
    end

    get %r{/(.*)/archive/(.*)?\.(tar\.gz|tgz|zip)} do
      repo, ref, format = params[:captures]
      safe_action(repo, ref) do
        configure_env(repo)
        filename = dolt.archive(repo, ref, format)
        add_sendfile_headers(filename, format)
        body("")
      end
    end

    private
    attr_reader :lookup, :renderer

    def dolt
      @dolt ||= ::Dolt::Sinatra::Actions.new(self, lookup, renderer)
    end

    def safe_action(repo, ref = nil)
      begin
        yield
      rescue Rugged::ReferenceError => err
        if ref == "HEAD"
          render_empty_repository(repo)
        else
          render_non_existent_refspec(repo, ref, err)
        end
      rescue Rugged::TreeError => err
        render_non_existent_refspec(repo, ref, err)
      rescue StandardError => err
        raise err if !Rails.env.production?
        renderer.render({ :file => (Rails.root + "public/500.html").to_s }, {}, :layout => nil)
      end
    end

    def render_empty_repository(repository)
      pid, rid = repository.split("/")
      uid = request.session["user_id"]
      @template ||= (Rails.root + "app/views/repositories/_getting_started.html.erb").to_s
      project = Project.find_by_slug!(pid)
      renderer.render({ :file => @template }, {
          :repository => RepositoryPresenter.new(project.repositories.find_by_name!(rid)),
          :current_user => uid && User.find(uid),
          :session => session
        })
    end

    def render_non_existent_refspec(repository, ref, error)
      pid, rid = repository.split("/")
      uid = request.session["user_id"]
      @template ||= (Rails.root + "app/views/repositories/_non_existent_refspec.html.erb").to_s
      repo = Project.find_by_slug!(pid).repositories.find_by_name!(rid)
      renderer.render({ :file => @template }, {
          :repository => RepositoryPresenter.new(repo),
          :current_user => uid && User.find(uid),
          :session => session,
          :ref => ref,
          :error => error
        })
    end

    def add_sendfile_headers(filename, format)
      basename = File.basename(filename)
      user_path = basename.gsub("/", "_").gsub('"', '\"')

      response.headers["content-type"] = format == "zip" ? "application/x-zip" : "application/x-gzip"
      response.headers["content-disposition"] = "Content-Disposition: attachment; filename=\"#{user_path}\""

      if Gitorious.frontend_server == "nginx"
        response.headers["x-accel-redirect"] = "/tarballs/#{basename}"
      else
        response.headers["x-sendfile"] = filename
      end
    end

    def force_ref(repo, pathlike, action)
      repository = dolt.resolve_repository(repo)

      begin
        # The original URL may have been missing the trailing comma if trying to
        # browse the root director (e.g. it was like
        # /project/repository/source/master when it should have been like
        # /project/repository/source/master:). If this is the case, we should be
        # able to find the oid corresponding to the ref.
        ref = repository.rev_parse_oid(pathlike)
        dolt.redirect("/#{repo}/#{action}/#{ref}:")
      rescue Rugged::ReferenceError => err
        # A reference error from Rugged tells us the path-like was not a valid
        # ref or oid. Treat it as a path instead, and show it from the default
        # HEAD for the repository.
        ref = repository.head_candidate_name
        dolt.redirect("/#{repo}/#{action}/#{ref}:" + pathlike)
      end
    end

    def configure_env(repo_slug)
      env["dolt"] = { :repository => repo_slug }
      begin
        verify_site_context!(Project.find_by_slug(repo_slug.split("/").first))
      rescue UnexpectedSiteContext => err
        redirect(err.target)
      end
    end

    def env_data
      { :env => env, :current_site => current_site, :session => session }
    end
  end
end
