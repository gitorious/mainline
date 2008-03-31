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
  VALID_SHA = /[a-zA-Z0-9~\{\}\^\.\-_]+/
  map.root :controller => "site", :action => "index"
  
  map.resource :account, :member => {:password => :get, :update_password => :put} do |account|
    account.resources :keys
  end
  map.connect "users/activate/:activation_code", :controller => "users", :action => "activate"
  map.resources :users, :requirements => {:id => /.+/}
  map.resource  :sessions
  map.with_options(:controller => "projects", :action => "category") do |project_cat|
    project_cat.projects_category "projects/category/:id"
    project_cat.formatted_projects_category "projects/category/:id.:format"
  end
  map.resources :projects, :member => {:confirm_delete => :get} do |projects|
    projects.resources(:repositories, :member => { 
      :new => :get, :create => :post, 
      :writable_by => :get, 
      :confirm_delete => :get
    }, :as => "repos") do |repo|
      repo.resources :committers, :name_prefix => nil, :collection => {:auto_complete_for_user_login => :post, :list => :get, :create => :post}
      repo.resources :comments, :member => { :commmit => :get  }
      repo.resources :merge_requests, :member => { :resolve => :put }
      repo.commit_comment "comments/commit/:sha", :controller => "comments", 
        :action => "commit", :conditions => { :method => :get }
      
      repo.resources :logs, :requirements => { :id => VALID_SHA }#, :member => { :feed => :get }
      repo.formatted_log_feed "logs/:id/feed.:format", :controller => "logs", :action => "feed", 
        :conditions => {:feed => :get}, :requirements => {:id => VALID_SHA}
      repo.resources :commits
      repo.trees          "trees/", :controller => "trees", :action => "index"
      repo.with_options(:requirements => { :id => VALID_SHA }) do |r|
        r.tree           "trees/:id/*path", :controller => "trees", :action => "show"
        r.formatted_tree "trees/:id/*path.:format", :controller => "trees", :action => "show"
        r.archive_tree   "archive/:id.tar.gz", :controller => "trees", :action => "archive"
        r.raw_blob       "blobs/raw/:id/*path", :controller => "blobs", :action => "raw"
        r.blob           "blobs/:id/*path", :controller => "blobs", :action => "show"
      end
    end
  end
  
  map.resource :search
  
  map.with_options :controller => 'sessions' do |session|
    session.login    '/login',  :action => 'new'
    session.logout   '/logout', :action => 'destroy'
  end

  map.dashboard "dashboard", :controller => "site", :action => "dashboard"  
  map.about "about", :controller => "site", :action => "about"
  map.faq "about/faq", :controller => "site", :action => "faq"

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
