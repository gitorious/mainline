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
  
  map.root :controller => "projects" # TODO change eventually
  
  map.resource :account do |account|
    account.resources :keys
  end
  map.resources :users 
  map.resource  :sessions
  map.resources :projects, :path_name => "p" do |projects|
    projects.resources(:repositories, :member => { 
      :copy => :get, :create_copy => :post, :writable_by => :get
    }, :path_name => "repos") do |repo|
      repo.resources :committers, :name_prefix => nil
      
      # Repository browsing related routes
      repo.with_options(:controller => "browse") do |r|
        r.browse  "browse",       :action => "index"
        r.tree    "tree/:sha",    :action => "tree", :sha => nil
        r.blob    "blob/:sha/:filename", :action => "blob", :requirements => {:filename => /.*/}
        r.raw_blob "raw/:sha/:filename", :action => "raw", :requirements => {:filename => /.*/}
        r.commit  "commit/:sha",  :action => "commit"
        r.diff    "diff/:sha/:other_sha",  :action => "diff"
      end
    end
  end
  
  map.with_options :controller => 'sessions' do |session|
    session.login    '/login',  :action => 'new'
    session.logout   '/logout', :action => 'destroy'
  end
  
  map.connect "users/activate/:activation_code", :controller => "users", :action => "activate"

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
