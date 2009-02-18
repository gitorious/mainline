ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  #map.connect ':controller/service.wsdl', :action => 'wsdl'
  
  VALID_REF = /[a-zA-Z0-9~\{\}\+\^\.\-_\/]+/
  
  repository_proc = proc do |repo|
    repo.resources :comments, :member => { :commmit => :get  }
    repo.commit_comment "comments/commit/:sha", :controller => "comments", 
      :action => "commit", :conditions => { :method => :get }
    repo.resources :merge_requests, :member => { 
      :resolve => :put 
    }, :collection => { 
      :create => :post, 
      :commit_list => :post,
      :target_branches => :post,
    }
    repo.resources :committerships, :collection => {:auto_complete_for_group_name => :post}
    
    repo.formatted_commits_feed "commits/*branch/feed.:format", 
        :controller => "commits", :action => "feed", :conditions => {:feed => :get}
    repo.commits        "commits", :controller => "commits", :action => "index"
    repo.commits_in_ref "commits/*branch", :controller => "commits", :action => "index"
    repo.commit         "commit/:id.:format", :controller => "commits", :action => "show"
    repo.trees          "tree/", :controller => "trees", :action => "index"
    repo.tree           "tree/*branch_and_path", :controller => "trees", :action => "show"
    repo.formatted_tree "trees/*branch_and_path.:format", :controller => "trees", :action => "show"
    repo.archive_tar    "archive-tarball/*branch", :controller => "trees", :action => "archive", :archive_format => "tar.gz"
    #repo.archive_zip    "archive-zip/*branch", :controller => "trees", :action => "archive", :archive_format => "zip"
    repo.raw_blob       "blobs/raw/*branch_and_path", :controller => "blobs", :action => "raw"
    repo.blob           "blobs/*branch_and_path", :controller => "blobs", :action => "show"
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
  
  map.resource :account, :member => {:password => :get, :update_password => :put} do |account|
    account.resources :keys
    account.resource :license
  end
  map.connect "users/activate/:activation_code", :controller => "users", :action => "activate"
  map.resources(:users, :requirements => {:id => /#{User::USERNAME_FORMAT}/ }, :collection => {
    :forgot_password => :get,
    :reset_password => :post
  }, :member => { :feed => :get }) do |user|
    user.resources(:repositories, repository_options, &repository_proc)
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
    grp.resources(:repositories, repository_options, &repository_proc)
  end
  map.resources :projects, :member => {:confirm_delete => :get} do |projects|
    projects.resources :pages, :member => { :history => :get }
    projects.resources(:repositories, repository_options, &repository_proc)
  end
  
  map.resource :search
  
  map.with_options :controller => 'sessions' do |session|
    session.login    '/login',  :action => 'new'
    session.logout   '/logout', :action => 'destroy'
  end

  map.dashboard "dashboard", :controller => "site", :action => "dashboard"  
  map.about "about", :controller => "site", :action => "about"
  map.faq "about/faq", :controller => "site", :action => "faq"

  map.namespace :admin do |admin|
    admin.resources :users, :member => { :suspend => :put, :unsuspend => :put, :reset_password => :put }
  end

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
  
  # See the routing_filter plugin and lib/route_filters/*
  map.filter "repository_owner_namespacing", :file => "route_filters/repository_owner_namespacing"
end
