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
  VALID_SHA = /[a-zA-Z0-9~\{\}\^\.]+/
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
  map.resources :projects do |projects|
    projects.resources(:repositories, :member => { 
      :new => :get, :create => :post, :writable_by => :get
    }, :path_name => "repos") do |repo|
      repo.resources :committers, :name_prefix => nil, :collection => {:auto_complete_for_user_login => :post}
      repo.resources :comments
      repo.commit_comment "comments/commit/:sha", :controller => "comments", 
        :action => "commit", :conditions => { :method => :get }
      
      # Repository browsing related routes
      repo.with_options(:controller => "browse") do |r|
        r.browse  "browse",           :action => "index"
        r.formatted_browse "browse.:format", :action => "index"
        r.log     "log",              :action => "log"
        r.tree    "tree/:sha/*path",  :action => "tree", 
          :sha => nil, :path => [], :requirements => {:sha => VALID_SHA}
        r.blob    "blob/:sha/*path",  :action => "blob", 
          :path => [], :requirements => {:sha => VALID_SHA}
        r.raw_blob "raw/:sha/*path",  :action => "raw", 
          :path => [], :requirements => {:sha => VALID_SHA}
        r.commit  "commit/:sha",      :action => "commit", 
          :requirements => {:sha => VALID_SHA}
        r.diff    "diff/:sha/:other_sha",  :action => "diff",
          :requirements => {:sha => VALID_SHA, :other_sha => VALID_SHA}
      end
    end
  end
  
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
