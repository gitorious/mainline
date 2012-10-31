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

Gitorious::Application.routes.draw do
  # Helper that builds repository routes in a given context
  def route_repositories
    # Listing repositories and creating new ones happens over
    # /~<user>/repositories/, e.g:
    # /~zmalltalker/repositories/new
    resources :repositories, :only => [:index, :new, :create]

    # Browsing, editing and destroying existing repositories happens over
    # /~<user>/<repository_name>/, e.g.:
    # /~zmalltalker/mainline/
    # /~zmalltalker/mainline/edit
    resources(:repositories, {
                :path => "/",
                :only => [:show, :edit, :update, :destroy]
              }) do
      member do
        post :create_clone
        get :clone
        get :search_clones
        get :committers
        get :confirm_delete
        get :writable_by
        match "config" => "repositories#repository_config"
      end

      resources :comments

      match "comments/commit/:sha" => "comments#commit", :as => :commit_comment, :via => :get
      match "comments/preview" => "comments#preview", :as => :comments_preview

      resources :merge_requests do
        collection do
          post :create
          post :commit_list
          post :target_branches
        end

        member do
          get :commit_status
          get :version
          get :terms_accepted
        end

        resources :comments do
          collection do
            post :preview
          end
        end

        resources :merge_request_versions do
          resources :comments do
            collection do
              post :preview
            end
          end
        end
      end

      resources :repository_memberships
      resources :committerships

      match "commits/*branch/feed.:format" => "commits#feed", :as => :formatted_commits_feed#, :via =>
      match "commits" => "commits#index", :as => :commits
      match "commits/*branch" => "commits#index", :as => :commits_in_ref
      match "graph" => "graphs#index", :as => :graph
      match "graph/*branch" => "graphs#index", :as => :graph_in_ref
      match "commit/:id/comments" => "commit_comments#index", :as => :commit_comments, :id => /[^\/]+/
      match "commit/:id/diffs" => "commit_diffs#index", :as => :commit_diffs, :id => /[^\/]+/
      match "commit/:from_id/diffs/:id" => "commit_diffs#compare", :as => :commit_compare
      match "commit/:id" => "commits#show", :as => :commit, :id => /.*/
      match "trees/" => "trees#index", :as => :trees
      match "trees/*branch_and_path" => "trees#show", :as => :tree
      match "trees/*branch_and_path.:format" => "trees#show", :as => :formatted_tree
      match "archive-tarball/*branch" => "trees#archive", :as => :archive_tar, :archive_format => "tar.gz"
      match "blobs/raw/*branch_and_path" => "blobs#raw", :as => :raw_blob
      match "blobs/history/*branch_and_path" => "blobs#history", :as => :blob_history
      match "blobs/blame/*branch_and_path" => "blobs#blame", :as => :blame
      match "blobs/*branch_and_path" => "blobs#show", :as => :blob
    end
  end

  ##################
  # Actual routing #
  ##################

  # R0. Site index
  root :to => "site#index"

  # R1. User routes
  resources :users, :only => [:index, :new, :create]

  get "/~:id(.:format)" => "users#show", :as => "user", :id => /[^\/]+/
  get "/~:id/edit(.:format)" => "users#edit", :as => "edit_user", :id => /[^\/]+/
  put "/~:id(.:format)" => "users#update", :id => /[^\/]+/
  delete "/~:id(.:format)" => "users#destroy", :id => /[^\/]+/

  scope "/~:id", :id => /[^\/]+/ do
    get "/forgot_password" => "users#forgot_password", :as => "user_forgot_password"
    post "/forgot_password_create" => "users#forgot_password_create"
    get "/openid_build" => "users#openid_build", :as => "user_openid_build"
    post "/openid_create" => "users#openid_create", :as => "user_openid_create"
    get "/delete_current" => "users#delete_current", :as => "user_delete_current"
    delete "/avatar" => "users#avatar"
    get "/watchlist" => "users#watchlist", :as => "user_watchlist"
    get "/password" => "users#password", :as => "user_password"
    get "/feed" => "users#feed", :as => "user_feed"
    put "/update_password" => "users#update_password", :as => "user_password"
  end

  scope "/~:user_id", :user_id => /[^\/]+/ do
    resources :keys

    resources :aliases do
      member do
        get :confirm
      end
    end

    resource :license
    route_repositories
    match "/:project/*slug" => redirect("/%{project}/%{slug}")
  end

  get "/users/activate/:activation_code" => "users#activate"
  get "/users/pending_activation" => "users#pending_activation"
  get "/users/reset_password/:token" => "users#reset_password", :as => :reset_password

  # R2. Groups
  resources :groups, :only => [:index, :new, :create]

  get "/+:id(.:format)" => "groups#show", :as => "group", :id => /[^\/]+/
  get "/+:id/edit(.:format)" => "groups#edit", :as => "edit_group", :id => /[^\/]+/
  put "/+:id(.:format)" => "groups#update", :id => /[^\/]+/
  delete "/+:id(.:format)" => "groups#destroy", :id => /[^\/]+/

  scope "/+:id", :id => /[^\/]+/ do
    delete "avatar" => "groups#avatar"
  end

  scope "/+:group_id", :id => /[^\/]+/ do
    resources :memberships
    route_repositories
    match "/:project/*slug" => redirect("/%{project}/%{slug}")
  end

  # R3. ???

  resources :events do
    member do
      get :commits
    end
  end

  resources :user_auto_completions, :only => [:index]
  resources :group_auto_completions, :only => [:index]

  match "/sessions" => "sessions#create", :as => :open_id_complete, :via => :get

  resource :sessions







  match "wiki/:site_id/config" => "site_wiki_pages#config", :as => :site_wiki_git_access_connect
  match "wiki/:site_id/writable_by" => "site_wiki_pages#writable_by", :as => :site_wiki_git_writable_by

  resources :site_wiki_pages do
    collection do
      get :git_access
    end

    member do
      put :preview
      get :history
    end
  end

  resource :search
  resources :messages do
    collection do
      get :sent
      put :bulk_update
      get :all
      get :auto_complete_for_message_recipients
    end

    member do
      post :reply
      put :read
    end
  end

  match "/login" => "sessions#new", :as => :login
  match "/logout" => "sessions#destroy", :as => :logout
  match "/dashboard" => "site#dashboard", :as => :dashboard
  match "/about" => "site#about", :as => :about
  match "/about/:action" => "site#index", :as => :about_page
  match "/contact" => "site#contact", :as => :contact

  namespace :api do
    match ":project_id/:repository_id/log/graph" => "graphs#show", :branch => "master"
    match ":project_id/:repository_id/log/graph/*branch" => "graphs#show"
  end

  namespace :admin do
    resources :users do
      member do
        put :suspend
        put :flip_admin_status
        put :unsuspend
        put :reset_password
      end
    end

    resource :oauth_settings

    resources :repositories do
      member do
        put :recreate
      end
    end

    match "diagnostics" => "diagnostics#index"
    match "project_proposals" => "project_proposals#index"
    match "project_proposals/new" => "project_proposals#new"
    match "project_proposals/create" => "project_proposals#create"
    match "project_proposals/reject" => "project_proposals#reject"
    match "project_proposals/approve" => "project_proposals#approve"
  end

  resources :favorites

  match "/activities" => "site#public_timeline", :as => :activity
  match "/merge_request_landing_page" => "merge_requests#oauth_return", :as => :merge_request_landing_page
  match "/merge_requests/:id" => "merge_requests#direct_access", :as => :merge_request_direct_access

  get "/projects(.:format)" => "projects#index"
  get "/:id/edit(.:format)" => "projects#edit"

  resources :projects, :path => "/" do
    member do
      put :preview
      get :edit_slug
      put :edit_slug
      get :clones
      get :confirm_delete
    end

    resources :project_memberships

    resources :pages do
      collection do
        get :git_access
      end

      member do
        put :preview
        get :history
      end
    end

    route_repositories
  end
end
