Gitorious::Application.routes.draw do
  root :to => 'site#index'
  match 'users/activate/:activation_code' => 'users#activate'
  match 'users/pending_activation' => 'users#pending_activation'
  match 'users/reset_password/:token' => 'users#reset_password', :as => :reset_password

  resources :users do
    collection do
      get :forgot_password
      post :forgot_password_create
      get :openid_build
      post :openid_create
    end

    member do
      get :delete_current
      delete :avatar
      get :watchlist
      get :password
      get :feed
      put :update_password
    end

    resources :keys

    resources :aliases do
      member do
        get :confirm
      end
    end

    resource :license

    resources :repositories do
      member do
        post :create_clone
        get :clone
        get :search_clones
        get :config
        get :committers
        get :confirm_delete
        get :writable_by
      end

      resources :comments

      match 'comments/commit/:sha' => 'comments#commit', :as => :commit_comment, :via => :get
      match 'comments/preview' => 'comments#preview', :as => :comments_preview

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

      match 'commits/*branch/feed.:format' => 'commits#feed', :as => :formatted_commits_feed#, :via =>
      match 'commits' => 'commits#index', :as => :commits
      match 'commits/*branch' => 'commits#index', :as => :commits_in_ref
      match 'graph' => 'graphs#index', :as => :graph
      match 'graph/*branch' => 'graphs#index', :as => :graph_in_ref
      match 'commit/:id/comments' => 'commit_comments#index', :as => :commit_comments, :id => /[^\/]+/
      match 'commit/:id/diffs' => 'commit_diffs#index', :as => :commit_diffs, :id => /[^\/]+/
      match 'commit/:from_id/diffs/:id' => 'commit_diffs#compare', :as => :commit_compare
      match 'commit/:id' => 'commits#show', :as => :commit, :id => /.*/
      match 'trees/' => 'trees#index', :as => :trees
      match 'trees/*branch_and_path' => 'trees#show', :as => :tree
      match 'trees/*branch_and_path.:format' => 'trees#show', :as => :formatted_tree
      match 'archive-tarball/*branch' => 'trees#archive', :as => :archive_tar, :archive_format => 'tar.gz'
      match 'blobs/raw/*branch_and_path' => 'blobs#raw', :as => :raw_blob
      match 'blobs/history/*branch_and_path' => 'blobs#history', :as => :blob_history
      match 'blobs/blame/*branch_and_path' => 'blobs#blame', :as => :blame
      match 'blobs/*branch_and_path' => 'blobs#show', :as => :blob
    end

    resources :projects do
      resources :repositories do
        member do
          post :create_clone
          get :clone
          get :search_clones
          get :config
          get :committers
          get :confirm_delete
          get :writable_by
        end

        resources :comments

        match 'comments/commit/:sha' => 'comments#commit', :as => :commit_comment, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }, :via => :get
        match 'comments/preview' => 'comments#preview', :as => :comments_preview, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }

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

        match 'commits/*branch/feed.:format' => 'commits#feed', :as => :formatted_commits_feed, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }#, :via =>
        match 'commits' => 'commits#index', :as => :commits, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'commits/*branch' => 'commits#index', :as => :commits_in_ref, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'graph' => 'graphs#index', :as => :graph, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'graph/*branch' => 'graphs#index', :as => :graph_in_ref, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'commit/:id/comments' => 'commit_comments#index', :as => :commit_comments, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }, :id => /[^\/]+/
        match 'commit/:id/diffs' => 'commit_diffs#index', :as => :commit_diffs, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }, :id => /[^\/]+/
        match 'commit/:from_id/diffs/:id' => 'commit_diffs#compare', :as => :commit_compare, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'commit/:id' => 'commits#show', :as => :commit, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }, :id => /.*/
        match 'trees/' => 'trees#index', :as => :trees, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'trees/*branch_and_path' => 'trees#show', :as => :tree, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'trees/*branch_and_path.:format' => 'trees#show', :as => :formatted_tree, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'archive-tarball/*branch' => 'trees#archive', :as => :archive_tar, :archive_format => 'tar.gz', :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'blobs/raw/*branch_and_path' => 'blobs#raw', :as => :raw_blob, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'blobs/history/*branch_and_path' => 'blobs#history', :as => :blob_history, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'blobs/blame/*branch_and_path' => 'blobs#blame', :as => :blame, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
        match 'blobs/*branch_and_path' => 'blobs#show', :as => :blob, :constraints => { :user_id => /(?i-mx:[a-z0-9\-_\.]+)/i }
      end
    end
  end

  resources :events do
    member do
      get :commits
    end
  end

  resources :user_auto_completions, :only => [:index]
  resources :group_auto_completions, :only => [:index]

  #match '/sessions' => 'sessions#create', :as => :open_id_complete, :constraints => { :method => :get }
  match '/sessions' => 'sessions#create', :as => :open_id_complete, :via => :get

  resource :sessions

  resources :groups do
    member do
      delete :avatar
    end

    resources :memberships
    resources :repositories do

      member do
        post :create_clone
        get :clone
        get :search_clones
        get :config
        get :committers
        get :confirm_delete
        get :writable_by
      end

      resources :comments

      match 'comments/commit/:sha' => 'comments#commit', :as => :commit_comment, :via => :get
      match 'comments/preview' => 'comments#preview', :as => :comments_preview

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
      match 'commits/*branch/feed.:format' => 'commits#feed', :as => :formatted_commits_feed#, :via =>
      match 'commits' => 'commits#index', :as => :commits
      match 'commits/*branch' => 'commits#index', :as => :commits_in_ref
      match 'graph' => 'graphs#index', :as => :graph
      match 'graph/*branch' => 'graphs#index', :as => :graph_in_ref
      match 'commit/:id/comments' => 'commit_comments#index', :as => :commit_comments, :id => /[^\/]+/
      match 'commit/:id/diffs' => 'commit_diffs#index', :as => :commit_diffs, :id => /[^\/]+/
      match 'commit/:from_id/diffs/:id' => 'commit_diffs#compare', :as => :commit_compare
      match 'commit/:id' => 'commits#show', :as => :commit, :id => /.*/
      match 'trees/' => 'trees#index', :as => :trees
      match 'trees/*branch_and_path' => 'trees#show', :as => :tree
      match 'trees/*branch_and_path.:format' => 'trees#show', :as => :formatted_tree
      match 'archive-tarball/*branch' => 'trees#archive', :as => :archive_tar, :archive_format => 'tar.gz'
      match 'blobs/raw/*branch_and_path' => 'blobs#raw', :as => :raw_blob
      match 'blobs/history/*branch_and_path' => 'blobs#history', :as => :blob_history
      match 'blobs/blame/*branch_and_path' => 'blobs#blame', :as => :blame
      match 'blobs/*branch_and_path' => 'blobs#show', :as => :blob
    end

    resources :projects do
      resources :repositories do
        member do
          post :create_clone
          get :clone
          get :search_clones
          get :config
          get :committers
          get :confirm_delete
          get :writable_by
        end

        resources :comments

        match 'comments/commit/:sha' => 'comments#commit', :as => :commit_comment, :via => :get
        match 'comments/preview' => 'comments#preview', :as => :comments_preview

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

        match 'commits/*branch/feed.:format' => 'commits#feed', :as => :formatted_commits_feed#, :via =>
        match 'commits' => 'commits#index', :as => :commits
        match 'commits/*branch' => 'commits#index', :as => :commits_in_ref
        match 'graph' => 'graphs#index', :as => :graph
        match 'graph/*branch' => 'graphs#index', :as => :graph_in_ref
        match 'commit/:id/comments' => 'commit_comments#index', :as => :commit_comments, :id => /[^\/]+/
        match 'commit/:id/diffs' => 'commit_diffs#index', :as => :commit_diffs, :id => /[^\/]+/
        match 'commit/:from_id/diffs/:id' => 'commit_diffs#compare', :as => :commit_compare
        match 'commit/:id' => 'commits#show', :as => :commit, :id => /.*/
        match 'trees/' => 'trees#index', :as => :trees
        match 'trees/*branch_and_path' => 'trees#show', :as => :tree
        match 'trees/*branch_and_path.:format' => 'trees#show', :as => :formatted_tree
        match 'archive-tarball/*branch' => 'trees#archive', :as => :archive_tar, :archive_format => 'tar.gz'
        match 'blobs/raw/*branch_and_path' => 'blobs#raw', :as => :raw_blob
        match 'blobs/history/*branch_and_path' => 'blobs#history', :as => :blob_history
        match 'blobs/blame/*branch_and_path' => 'blobs#blame', :as => :blame
        match 'blobs/*branch_and_path' => 'blobs#show', :as => :blob
      end
    end
  end

  match 'wiki/:site_id/config' => 'site_wiki_pages#config', :as => :site_wiki_git_access_connect
  match 'wiki/:site_id/writable_by' => 'site_wiki_pages#writable_by', :as => :site_wiki_git_writable_by

  resources :site_wiki_pages do
    collection do
      get :git_access
    end

    member do
      put :preview
      get :history
    end
  end

  resources :projects do
    member do
      put :preview
      #any :edit_slug
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

    resources :repositories do
      member do
        post :create_clone
        get :clone
        get :search_clones
        get :config
        get :committers
        get :confirm_delete
        get :writable_by
      end

      resources :comments

      match 'comments/commit/:sha' => 'comments#commit', :as => :commit_comment, :via => :get
      match 'comments/preview' => 'comments#preview', :as => :comments_preview

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
      match 'commits/*branch/feed.:format' => 'commits#feed', :as => :formatted_commits_feed#, :via =>
      match 'commits' => 'commits#index', :as => :commits
      match 'commits/*branch' => 'commits#index', :as => :commits_in_ref
      match 'graph' => 'graphs#index', :as => :graph
      match 'graph/*branch' => 'graphs#index', :as => :graph_in_ref
      match 'commit/:id/comments' => 'commit_comments#index', :as => :commit_comments, :id => /[^\/]+/
      match 'commit/:id/diffs' => 'commit_diffs#index', :as => :commit_diffs, :id => /[^\/]+/
      match 'commit/:from_id/diffs/:id' => 'commit_diffs#compare', :as => :commit_compare
      match 'commit/:id' => 'commits#show', :as => :commit, :id => /.*/
      match 'trees/' => 'trees#index', :as => :trees
      match 'trees/*branch_and_path' => 'trees#show', :as => :tree
      match 'trees/*branch_and_path.:format' => 'trees#show', :as => :formatted_tree
      match 'archive-tarball/*branch' => 'trees#archive', :as => :archive_tar, :archive_format => 'tar.gz'
      match 'blobs/raw/*branch_and_path' => 'blobs#raw', :as => :raw_blob
      match 'blobs/history/*branch_and_path' => 'blobs#history', :as => :blob_history
      match 'blobs/blame/*branch_and_path' => 'blobs#blame', :as => :blame
      match 'blobs/*branch_and_path' => 'blobs#show', :as => :blob
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

  match '/login' => 'sessions#new', :as => :login
  match '/logout' => 'sessions#destroy', :as => :logout
  match 'dashboard' => 'site#dashboard', :as => :dashboard
  match 'about' => 'site#about', :as => :about
  match 'about/:action' => 'site#index', :as => :about_page
  match 'contact' => 'site#contact', :as => :contact

  namespace :api do
    match ':project_id/:repository_id/log/graph' => 'graphs#show', :branch => 'master'
    match ':project_id/:repository_id/log/graph/*branch' => 'graphs#show'
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

    match 'diagnostics' => 'diagnostics#index'
    match 'project_proposals' => 'project_proposals#index'
    match 'project_proposals/new' => 'project_proposals#new'
    match 'project_proposals/create' => 'project_proposals#create'
    match 'project_proposals/reject' => 'project_proposals#reject'
    match 'project_proposals/approve' => 'project_proposals#approve'
  end

  resources :favorites

  match '/activities' => 'site#public_timeline', :as => :activity
  match '/merge_request_landing_page' => 'merge_requests#oauth_return', :as => :merge_request_landing_page
  match '/merge_requests/:id' => 'merge_requests#direct_access', :as => :merge_request_direct_access
  match '/:controller(/:action(/:id))'
end
