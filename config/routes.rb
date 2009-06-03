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
        :resolve => :put,
        :terms_accepted => :get,
        :reopen => :put
      }, :collection => { 
        :create => :post, 
        :commit_list => :post,
        :target_branches => :post,
      }, :has_many => :comments
      repo.resources :committerships, :collection => {
        :auto_complete_for_group_name => :post,
        :auto_complete_for_user_login => :post
      }

      repo.formatted_commits_feed "commits/*branch/feed.:format",
          :controller => "commits", :action => "feed", :conditions => {:feed => :get}
      repo.commits        "commits", :controller => "commits", :action => "index"
      repo.commits_in_ref "commits/*branch", :controller => "commits", :action => "index"
      repo.commit         "commit/:id.:format", :controller => "commits", :action => "show"
      repo.trees          "trees/", :controller => "trees", :action => "index"
      repo.tree           "trees/*branch_and_path", :controller => "trees", :action => "show"
      repo.formatted_tree "trees/*branch_and_path.:format", :controller => "trees", :action => "show"
      repo.archive_tar    "archive-tarball/*branch", :controller => "trees", :action => "archive", :archive_format => "tar.gz"
      #repo.archive_zip    "archive-zip/*branch", :controller => "trees", :action => "archive", :archive_format => "zip"
      repo.raw_blob       "blobs/raw/*branch_and_path", :controller => "blobs", :action => "raw"
      repo.blob_history   "blobs/history/*branch_and_path", :controller => "blobs", :action => "history"
      repo.blob           "blobs/*branch_and_path", :controller => "blobs", :action => "show"
    end
  end
  repository_options = {
    :member => {
      :clone => :get, :create_clone => :post,
      :writable_by => :get, 
      :confirm_delete => :get,
      :committers => :get,
    }
  }
  
    
  map.root :controller => "site", :action => "index"
  
  map.connect "users/activate/:activation_code", :controller => "users", :action => "activate"
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
    :avatar => :delete
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
  map.resources :groups, :as => "teams" do |grp|
    grp.resources :memberships, :collection => {:auto_complete_for_user_login => :post}
    grp.resources(:repositories, repository_options){|r| build_repository_routes(r) }
    grp.resources :projects do |p|
      p.resources(:repositories, repository_options){|r| build_repository_routes(r) }
    end
  end
  map.resources :projects, :member => {:confirm_delete => :get, :preview => :put, :edit_slug => :any} do |projects|
    projects.resources :pages, :member => { :history => :get,:preview => :put }
    projects.resources(:repositories, repository_options){|r| build_repository_routes(r) }
  end


  
  map.resource :search
  
  map.resources :messages, 
    :member => {:reply => :post, :read => :put}, 
    :collection => {:auto_complete_for_recipient_login => :post, :sent => :get, :bulk_update => :put}
  
  map.with_options :controller => 'sessions' do |session|
    session.login    '/login',  :action => 'new'
    session.logout   '/logout', :action => 'destroy'
  end
  
  map.dashboard "dashboard", :controller => "site", :action => "dashboard"  
  map.about "about", :controller => "site", :action => "about"
  map.faq "about/faq", :controller => "site", :action => "faq"
  map.contact "contact", :controller => "site", :action => "contact"
  
  map.namespace :admin do |admin|
    admin.resources :users, :member => { :suspend => :put, :unsuspend => :put, :reset_password => :put }
    admin.resource :oauth_settings, :path_prefix => "/admin/projects/:project_id"
    
  end
  
  map.merge_request_landing_page '/merge_request_landing_page', :controller => 'merge_requests', :action => 'oauth_return'
  
  map.merge_request_direct_access '/merge_requests/:id', :controller => 'merge_requests', :action => 'direct_access'
  
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
    
  # See the routing_filter plugin and lib/route_filters/*
  map.filter "repository_owner_namespacing", :file => "route_filters/repository_owner_namespacing"
end
