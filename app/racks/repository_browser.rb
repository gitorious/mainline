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

    def self.get_repo_ref_path(action, &blk)
      get(action, &blk)
      get(action.gsub(':', '%3a'), &blk)
      get(action.gsub(':', '%3A'), &blk)
    end

    def initialize(lookup, renderer)
      @lookup = lookup
      @renderer = renderer
      super()
    end

    def self.instance; @instance; end
    def self.instance=(instance); @instance = instance; end

    # Implementing this method and returning true means that
    # Dolt will redirect any requests to refs to the actual commit
    # oid, e.g.:
    #   GET /gitorious/mainline/source/master:
    #   -> 302 /gitorious/mainline/source/2d4e282d02f438043fc425cc99a781774d22561a:
    def redirect_refs?; true; end

    get_repo_ref_path '/*/source/*:*' do
      repo, ref, path = params[:splat]
      path.force_encoding('ascii-8bit')
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.tree_entry(repo, ref, path, env_data).sub(/class="container gts-body"/, "class=\"container gts-body\" id=\"gts-pjax-container\"")
      end
    end

    get_repo_ref_path "/*/raw/*:*" do
      repo, ref, path = params[:splat]
      path.force_encoding('ascii-8bit')
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.raw(repo, ref, path, env_data)
      end
    end

    get_repo_ref_path "/*/blame/*:*" do
      repo, ref, path = params[:splat]
      path.force_encoding('ascii-8bit')
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.blame(repo, ref, path, env_data)
      end
    end

    get_repo_ref_path "/*/history/*:*" do
      repo, ref, path = params[:splat]
      path.force_encoding('ascii-8bit')
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.history(repo, ref, path, (params[:commit_count] || 20).to_i, env_data)
      end
    end

    get_repo_ref_path "/*/tree_history/*:*" do
      repo, ref, path = params[:splat]
      path.force_encoding('ascii-8bit')
      safe_action(repo, ref) do
        configure_env(repo)
        dolt.tree_history(repo, ref, path, 1, env_data)
      end
    end

    get "/*/source/*" do
      safe_action(params[:splat].first) do
        force_ref(params[:splat][0], params[:splat][1], "source")
      end
    end

    get "/*/raw/*" do
      safe_action(params[:splat].first) do
        force_ref(params[:splat][0], params[:splat][1], "raw")
      end
    end

    get "/*/blame/*" do
      safe_action(params[:splat].first) do
        force_ref(params[:splat][0], params[:splat][1], "blame")
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

    get %r{/(.*)/archive/(.*)?\.(tar\.gz|tgz|zip)} do
      repo, ref, format = params[:captures]

      safe_action(repo, ref) do
        repository = dolt.resolve_repository(repo)
        raise RepositoryTooBigError.new if !Gitorious.tarballable?(repository)

        oid = lookup.rev_parse_oid(repo, ref)
        if oid != ref
          dolt.redirect("/#{repo}/archive/#{oid}.#{format}")
        else
          configure_env(repo)
          location = lookup.archive(repo, ref, format)
          add_accel_headers(location, format)
          body("")
        end
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
      rescue RepositoryTooBigError => err
        render_too_big_to_tarball(repo, ref)
      rescue StandardError => err
        raise err if !Rails.env.production?
        status 500
        renderer.render({ :file => (Rails.root + "public/500.html").to_s }, {}, :layout => nil)
      end
    end

    def render_too_big_to_tarball(repository, ref)
      pid, rid = repository.split("/")
      project = Project.find_by_slug!(pid)
      render({ :file => (Rails.root + "app/views/repositories/_too_big_to_tarball.html.erb").to_s }, {
          :repository => RepositoryPresenter.new(project.repositories.find_by_name!(rid)),
          :ref => ref
        })
    end

    def render_empty_repository(repository)
      pid, rid = repository.split("/")
      @template ||= (Rails.root + "app/views/repositories/_getting_started.html.erb").to_s
      project = Project.find_by_slug!(pid)
      render({ :file => @template }, {
          :repository => RepositoryPresenter.new(project.repositories.find_by_name!(rid)),
        })
    end

    def render_non_existent_refspec(repository, ref, error)
      pid, rid = repository.split("/")
      @template ||= (Rails.root + "app/views/repositories/_non_existent_refspec.html.erb").to_s
      repo = Project.find_by_slug!(pid).repositories.find_by_name!(rid)
      status 404
      render({ :file => @template }, {
          :repository => RepositoryPresenter.new(repo),
          :ref => ref,
          :error => error
        })
    end

    def render(template, locals, opts = {})
      renderer.render(template, {:session => session, :current_user => current_user}.merge(locals), opts)
    end

    def add_accel_headers(location, format)
      if location.include?("_internal") # it's an internal Nginx redirect
        response.headers["X-Accel-Redirect"] = location
      else # it's a file path
        basename = File.basename(location)
        filename = basename.gsub("/", "_").gsub('"', '\"')

        response.headers["Content-Type"] = format == "zip" ? "application/zip" : "application/x-gzip"
        response.headers["Content-Disposition"] = "attachment; filename=#{filename}"
        response.headers["X-Accel-Redirect"] = "/tarballs/#{basename}"
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

    def current_user
      uid = session["user_id"]
      uid && User.find(uid)
    end

    def env_data
      { :env => env, :current_site => current_site, :current_user => current_user, :session => session }
    end
  end

  class RepositoryTooBigError < StandardError
  end
end
