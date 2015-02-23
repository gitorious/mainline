# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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
  ### R0. Site index
  root :to => "site#index"

  get "/gitlab-import" => "gitlab_import#new"

  ### R1. Repository browser (instance is configured in an initializer)
  match "/:project_id/:repository_id/:action/*slug" => Gitorious::RepositoryBrowser.instance, :action => /(source|tree_history|raw|blame|history|archive)/, :as => :repository_browser
  match "/:project_id/:repository_id/refs" => Gitorious::RepositoryBrowser.instance, :as => :repository_refs

  ### R2. User routes
  resources :users, :only => [:new, :create] do
    collection do
      get "/forgot_password" => "password_resets#new", :as => :forgot_password
      post "/forgot_password" => "password_resets#generate_token", :as => :forgot_password_create
      get "/reset_password/:token" => "password_resets#prepare_reset", :as => :reset_password
      put "/reset_password/:token" => "password_resets#reset", :as => :do_reset_password
      get "/activate/:activation_code" => "user_activations#create"
      get "/pending_activation" => "user_activations#show", :as => :pending_activation
      get "/openid_build" => "open_id_users#new"
      post "/openid_create" => "open_id_users#create"
      get "/new" => "users#new"
      get "/view_state/repository/:id.:format" => "repository_view_state#show", :as => :repository_view_state
      get "/view_state/project/:id.:format" => "project_view_state#show", :as => :project_view_state
      get "/view_state.:format" => "user_view_state#show", :as => :view_state

      # Used to be we supported things like /users/~zmalltalker/mainline
      # No more, ~<user_name> is the canonical user URL namespace
      get "/*slug" => (redirect do |params, request|
                         request.fullpath.sub("users/", "~")
                       end), :slug => /.*/
    end
  end

  # `resources :users` can't do the ~<user> ids
  get "/~:id.keys" => "public_keys#index", :id => /[^\/]+/
  get "/~:id(.:format)" => "users#show", :as => "user", :id => /[^\/]+/
  get "/~:id/edit(.:format)" => "users#edit", :as => "edit_user", :id => /[^\/]+/
  put "/~:id(.:format)" => "users#update", :id => /[^\/]+/
  delete "/~:id(.:format)" => "users#destroy", :id => /[^\/]+/

  # Additional user actions
  scope "/~:id", :id => /[^\/]+/, :as => :user do
    get "/delete_current" => "users#destroy", :as => :delete_current
    delete "/avatar" => "avatars#destroy"
    get "/watchlist" => "user_watchlists#show", :as => :watchlist
    get "/feed" => "user_feeds#show", :as => :feed
    put "/update_password" => "passwords#update", :as => :update_password

    get "/aliases" => "users#edit", :defaults => { :tab => "email-aliases" }, :as => :edit_email_aliases
    get "/ssh-keys" => "users#edit", :defaults => { :tab => "ssh-keys" }, :as => :edit_ssh_keys
    get "/password" => "users#edit", :defaults => { :tab => "change-password" }, :as => :edit_password
    get "/favorites" => "users#edit", :defaults => { :tab => "manage-favorites" }, :as => :edit_favorites
  end

  # Nested user resources. This is in a separate scope because the
  # controllers expect params[:user_id] to contain the user, not
  # params[:id] as in the scope above
  scope "/~:user_id", :user_id => /[^\/]+/, :as => :user do
    resources :keys, :only => [:new, :create, :destroy, :index]

    resources :aliases do
      member do
        get :confirm
      end
    end

    get "/repositories" => "repositories#index"
    resource :license, :only => [:show, :edit, :update]
    match "/*slug" => "owner_redirections#show"
  end

  ### R3. Sessions
  resource :sessions
  get "/sessions" => "sessions#create", :as => :open_id_complete
  get "/login" => "sessions#new", :as => :login
  get "/login/http" => "sessions#http" # for Kerberos authentication
  get "/logout" => "sessions#destroy", :as => :logout

  ### R4. Groups
  resources :groups, :only => [:index, :new, :create]
  # `resource :groups` can't do the +<group> ids
  get "/+:id(.:format)" => "groups#show", :as => "group", :id => /[^\/]+/
  get "/+:id/edit(.:format)" => "groups#edit", :as => "edit_group", :id => /[^\/]+/
  put "/+:id(.:format)" => "groups#update", :id => /[^\/]+/
  delete "/+:id(.:format)" => "groups#destroy", :id => /[^\/]+/

  # Additional group actions
  scope "/+:id", :id => /[^\/]+/, :as => :group do
    delete "avatar" => "groups#avatar"
  end

  # Nested group resources. This is in a separate scope because the
  # controllers expect params[:group_id] to contain the group, not
  # params[:id] as in the scope above
  scope "/+:group_id", :id => /[^\/]+/, :as => :group do
    resources :memberships
    get "/repositories" => "repositories#index"
    match "/*slug" => "owner_redirections#show"
  end

  ### R5. Site-wide wiki
  get "/wiki/:site_id/config" => "site_wiki_pages#repository_config", :as => :site_wiki_git_access_connect
  get "/wiki/:site_id/writable_by" => "site_wiki_pages#writable_by", :as => :site_wiki_git_writable_by

  resources :site_wiki_pages, :path => "/wiki" do
    collection do
      get :git_access
    end

    member do
      get :history
    end
  end

  ### R6. Direct merge request access
  match "/merge_request_landing_page" => "merge_requests#oauth_return", :as => :merge_request_landing_page
  get "/merge_requests/:id" => "merge_requests#direct_access", :as => :merge_request_direct_access

  ### R7. Site controller, various loose pages
  get "/activities" => "site#public_timeline", :as => :activity
  get "/dashboard" => "site#dashboard", :as => :dashboard
  get "/my-activities" => "site#my_activities", :as => :dashboard_my_activities
  get "/about" => "site#about", :as => :about
  get "/about/:action" => "site#index", :as => :about_page
  get "/contact" => "site#contact", :as => :contact

  ### R8. Administration
  namespace :admin do
    get "/" => redirect { |params, request| "/admin/repositories" }

    resources :users, :only => [:index, :new, :create] do
      member do
        put :suspend
        put :flip_admin_status
        put :unsuspend
        put :reset_password
      end

      resources :keys, only: [:index, :new, :create, :destroy]
    end

    resources :projects, :only => [:show] do
      resource :oauth_settings, :only => [:show, :edit, :update]
    end

    resources :repositories, :only => [:index] do
      member do
        put :recreate
      end
    end

    resources :project_proposals, :only => [:index, :new, :create]
    post "/project_proposals/:id/reject" => "project_proposals#reject"
    post "/project_proposals/:id/approve" => "project_proposals#approve"
  end

  ### R9. API
  namespace :api do
    get ":project_id/:repository_id/log/graph(.:format)" => "graphs#show"
    get ":project_id/:repository_id/log/graph/*branch(.:format)" => "graphs#show"

    namespace :internal do
      get "/repo-config", to: "repository_configurations#show"
      get "/authenticate", to: "users#authenticate"
      get "/hooks/pre-receive", to: "hooks#pre_receive"
      post "/hooks/post-receive", to: "hooks#post_receive"
    end
  end

  ### R10. Events
  resources :events do
    member do
      get :commits
    end
  end

  ### R11. Additional logged in user resources
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

  resources :favorites, :only => [:index, :create, :update, :destroy]

  ### R12. Search
  get "/search", :controller => "searches", :action => "show", :as => :search

  ### R13. Auto-completion
  resources :user_auto_completions, :only => [:index]
  resources :group_auto_completions, :only => [:index]

  ### R14. Projects
  resources :projects, :only => [:index, :create]
  get "/:id/edit(.:format)" => "projects#edit"

  resources :projects, :path => "/" do
    member do
      put :preview
      get :edit_slug
      put :edit_slug
      get :confirm_delete
      get "/ownership/edit" => "project_ownerships#edit", :as => :transfer_ownership
      put "/ownership/edit" => "project_ownerships#update", :as => :transfer_ownership
    end

    resources :project_memberships, :only => [:index, :new, :create, :destroy]
    get "/community", :controller => :project_community, :action => :index
    get "/merge_requests", :controller => :project_merge_requests, :action => :index

    resources :pages do
      collection do
        get :git_access
      end

      member do
        get :history
      end
    end

    ### R14.2. Repositories

    # Listing repositories and creating new ones happens over
    # /<project>/repositories/, e.g:
    #   /gitorious/repositories/new
    resources :repositories, :only => [:index, :new, :create]

    # Browsing, editing and destroying existing repositories happens over
    # /<project>/<repository_name>/, e.g.:
    #   /gitorious/mainline
    #   /gitorious/mainline/edit
    resources(:repositories, {
                :path => "/",
                :only => [:show, :edit, :update, :destroy]
              }) do
      member do
        post "/create_clone" => "repository_clones#create"
        get "/clone" => "repository_clones#new"
        get "/search_clones" => "repository_clone_searches#show"
        get :committers
        get :confirm_delete
        get "/ownership/edit" => "repository_ownerships#edit", :as => :transfer_ownership
        put "/ownership/edit" => "repository_ownerships#update"
        get "/activities" => "repository_activities#index", :as => :activities
      end

      resources :comments, :controller => :repository_comments, :only => [:index]

      resources :services, :only => [:index, :destroy] do
        collection do
          post "/:service_type" => "services#create", :as => :create
          get "/:service_type" => "services#index"
        end
        resources :service_tests, :as => :tests, :only => [:create]
      end

      match "/community", :controller => :repository_community, :action => :index

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

        resources :comments, :controller => :merge_request_comments, :only => [:index, :create, :update]

        get "/diffs(/:version)" => "merge_request_versions#show", :as => :version
        get "/diffs/:version/comments/:commit_range(.:format)" => "merge_request_version_comments#index", :as => :version_comments
        post "/diffs/:version/comments/:commit_range" => "merge_request_version_comments#create", :as => :version_create_comment
        put "/diffs/:version/comments/:id" => "merge_request_version_comments#update", :as => :version_update_comment
        get "/diffs/:version/comments/:id/edit" => "merge_request_version_comments#edit", :as => :version_edit_comment
      end

      resources :repository_memberships, :only => [:new, :create, :destroy]
      resources :committerships, :only => [:index, :create, :edit, :update, :destroy]

      match "/commits/*id/feed(.:format)" => "commits#feed", :as => :formatted_commits_feed
      match "/commits" => "commits#index", :as => :commits
      match "/commits/*branch" => "commits#index", :as => :commits_in_ref, :branch => /.+/

      # Commit comments
      post "/commit/:ref/comments" => "commit_comments#create", :as => :create_commit_comment, :ref => /[^\/]+/
      put "/commit/:ref/comments/:id" => "commit_comments#update", :as => :update_commit_comment, :ref => /[^\/]+/
      get "/commit/:ref/comments.:format" => "commit_comments#index", :as => :commit_comments, :ref => /[^\/]+/

      match "/commit/:from_id/diffs/:id" => "commit_diffs#show", :as => :commit_compare

      match "/commit/:id.:format" => "commits#show", :as => :commit, :format => /diff|patch/
      match "/commit/:id" => "commits#show", :as => :commit, :id => /.*/

      match "/graph" => "graphs#index", :as => :graph
      match "/graph/*branch" => "graphs#index", :as => :graph_in_ref, :branch => /.*/

      match "/trees/" => "trees#index", :as => :trees
      match "/trees/*branch_and_path" => "trees#show", :as => :tree, :format => false

      # These URLs were introduced as a work-around for a Rails bug that
      # prevented URLs like /archive/:branch.:format. Now we can use the
      # "real" URLs, redirect these temps to the proper ones.
      get "/archive-tarball/*branch" => (redirect do |params, request|
        prefix = request.fullpath.split("/archive-tarball").first
        "#{prefix}/archive/#{URI.encode(params[:branch])}.tar.gz"
      end)

      match "/archive/*branch.tar.gz" => "trees#archive", :as => :archive_tar
      match "/archive/*branch.:archive_format" => "trees#archive", :as => :archive

      match "/blobs/raw/*branch_and_path" => "blobs#raw", :as => :raw_blob, :format => false
      match "/blobs/history/*branch_and_path" => "blobs#history", :as => :blob_history, :format => false
      match "/blobs/blame/*branch_and_path" => "blobs#blame", :as => :blame, :format => false
      match "/blobs/*branch_and_path" => "blobs#show", :as => :blob, :format => false
    end
  end

  # engines
  mount Issues::Engine => "/", :as => 'issues_app'
end
