# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008, 2009 Johan Sørensen <johan@johansorensen.com>
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


# == ROUTING NOTE =========================================================
#
# Note that all routes are getting pre and post processed by the filter class
# in RAILS_ROOT/lib/route_filters/repository_owner_namespacing.rb and that
# you should be EXTRA CAREFUL when adding a route that doesn't map directly
# by name to an existing controller or action. In such case the same string
# should be added to Gitorious::Reservations::unaccounted_root_names
#
# =========================================================================

ActionController::Routing::Routes.draw do |map|
  VALID_REF = /[a-zA-Z0-9~\{\}\+\^\.\-_\/]+/

  # Builds up the common repository sub-routes that's shared between projects
  # and user+team namespaced repositories
  def build_repository_routes(repository, options = {})
    repository.with_options(options) do |repo|
      repo.resources :comments
      repo.commit_comment "comments/commit/:sha", :controller => "comments",
        :action => "commit", :conditions => { :method => :get }
      repo.comments_preview 'comments/preview', :controller => 'comments',
        :action => 'preview'#, :conditions => {:method => :put}
      repo.resources :merge_requests, :member => {
        :terms_accepted => :get,
        :version => :get,
        :commit_status => :get
      }, :collection => {
        :create => :post,
        :commit_list => :post,
        :target_branches => :post,
      } do |merge_request|
        merge_request.resources :comments, :collection => {:preview => :post}
        merge_request.resources :merge_request_versions do |v|
          v.resources :comments, :collection => {:preview => :post}
        end
      end
      repo.resources :committerships, :collection => {
        :auto_complete_for_group_name => :get,
        :auto_complete_for_user_login => :get
      }

      repo.formatted_commits_feed("commits/*branch/feed.:format",
                                  :controller => "commits", :action => "feed", :conditions => { :feed => :get })
      repo.commits         "commits", :controller => "commits", :action => "index"
      repo.commits_in_ref  "commits/*branch", :controller => "commits", :action => "index"
      repo.graph           "graph", :controller => "graphs", :action => "index"
      repo.graph_in_ref    "graph/*branch", :controller => "graphs", :action => "index"
      repo.commit_comments "commit/:id/comments", :controller => "commit_comments", :action => "index", :id => /[^\/]+/
      repo.commit_diffs    "commit/:id/diffs", :controller => "commit_diffs", :action => "index", :id => /[^\/]+/
      repo.commit_compare  "commit/:from_id/diffs/:id", :controller => "commit_diffs", :action => "compare"
      repo.commit          "commit/:id", :controller => "commits", :action => "show", :id => /.*/
      repo.trees           "trees/", :controller => "trees", :action => "index"
      repo.tree            "trees/*branch_and_path", :controller => "trees", :action => "show"
      repo.formatted_tree  "trees/*branch_and_path.:format", :controller => "trees", :action => "show"
      repo.archive_tar     "archive-tarball/*branch", :controller => "trees", :action => "archive", :archive_format => "tar.gz"
      #repo.archive_zip    "archive-zip/*branch", :controller => "trees", :action => "archive", :archive_format => "zip"
      repo.raw_blob        "blobs/raw/*branch_and_path", :controller => "blobs", :action => "raw"
      repo.blob_history    "blobs/history/*branch_and_path", :controller => "blobs", :action => "history"
      repo.blame           "blobs/blame/*branch_and_path", :controller => "blobs", :action => "blame"
      repo.blob            "blobs/*branch_and_path", :controller => "blobs", :action => "show"
    end
  end

  repository_options = {
    :member => {
      :clone => :get, :create_clone => :post,
      :writable_by => :get,
      :config => :get,
      :confirm_delete => :get,
      :committers => :get,
      :search_clones => :get
    }
  }

  map.root :controller => "site", :action => "index"

  map.connect "users/activate/:activation_code", :controller => "users", :action => "activate"
  map.connect "users/pending_activation", :controller => "users", :action => "pending_activation"
  map.reset_password "users/reset_password/:token", :controller => "users", :action => "reset_password"
  map.resources(:users, :requirements => {:id => /#{User::USERNAME_FORMAT}/i }, :collection => {
    :forgot_password => :get,
    :forgot_password_create => :post,
    :openid_build => :get,
    :openid_create => :post
  }, :member => {
    :feed => :get,
    :password => :get,
    :update_password => :put,
    :avatar => :delete,
    :watchlist => :get
  }) do |user|
    user.with_options({:requirements => {:user_id => /#{User::USERNAME_FORMAT}/i}}) do |user_req|
      user_req.resources :keys
      user_req.resources :aliases, :member => { :confirm => :get }
      user_req.resource :license
      user_req.resources(:repositories, repository_options){|r| build_repository_routes(r) }
      user_req.resources :projects do |p|
        p.resources(:repositories, repository_options.merge({
          :requirements => {:user_id => /#{User::USERNAME_FORMAT}/i}
        })) do |repo|
          build_repository_routes(repo, {:requirements => {:user_id => /#{User::USERNAME_FORMAT}/i}})
        end
      end
    end
  end

  map.resources  :events, :member => {:commits => :get}

  map.open_id_complete '/sessions', :controller => "sessions", :action=> "create",:requirements => { :method => :get }

  map.resource  :sessions
  map.with_options(:controller => "projects", :action => "category") do |project_cat|
    project_cat.projects_category "projects/category/:id"
    project_cat.formatted_projects_category "projects/category/:id.:format"
  end
  map.resources :groups, :as => "teams", :member => {:avatar => :delete}  do |grp|
    grp.resources :memberships, :collection => {:auto_complete_for_user_login => :get}
    grp.resources(:repositories, repository_options){|r| build_repository_routes(r) }
    grp.resources :projects do |p|
      p.resources(:repositories, repository_options){|r| build_repository_routes(r) }
    end
  end

  map.resources :projects, :member => {
    :confirm_delete => :get,
    :preview => :put,
    :edit_slug => :any,
    :clones => :get
  } do |projects|
    projects.resources :pages, :member => { :history => :get,:preview => :put}, :collection => { :git_access => :get }
    projects.resources(:repositories, repository_options){|r| build_repository_routes(r) }
  end

  map.resource :search

  map.resources :messages,
    :member => {:reply => :post, :read => :put},
    :collection => {:auto_complete_for_message_recipients => :get, :sent => :get, :bulk_update => :put, :all => :get}

  map.with_options :controller => 'sessions' do |session|
    session.login    '/login',  :action => 'new'
    session.logout   '/logout', :action => 'destroy'
  end

  map.dashboard "dashboard", :controller => "site", :action => "dashboard"
  map.about "about", :controller => "site", :action => "about"
  map.about_page "about/:action", :controller => "site"
  map.contact "contact", :controller => "site", :action => "contact"

  map.namespace :api do |api|
    api.connect ':project_id/:repository_id/log/graph', :controller => 'graphs', :action => 'show', :branch => 'master'
    api.connect ':project_id/:repository_id/log/graph/*branch', :controller => 'graphs', :action => 'show'
  end

  map.namespace :admin do |admin|
    admin.resources :users, :member => { :suspend => :put, :unsuspend => :put, :reset_password => :put }
    admin.resource :oauth_settings, :path_prefix => "/admin/projects/:project_id"
    admin.resources :repositories, :member => {:recreate => :put}
  end

  map.resources :favorites

  map.activity "/activities", :controller => "site", :action => "public_timeline"

  map.merge_request_landing_page '/merge_request_landing_page', :controller => 'merge_requests', :action => 'oauth_return'

  map.merge_request_direct_access '/merge_requests/:id', :controller => 'merge_requests', :action => 'direct_access'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'

  # See the routing_filter plugin and lib/route_filters/*
  map.filter "repository_owner_namespacing", :file => "route_filters/repository_owner_namespacing"
end
