class SiteController < ApplicationController
  before_filter :login_required, :only => [:dashboard]
  
  def index
    @projects = Project.find(:all, :limit => 10, :order => "id desc")
  end
  
  def dashboard
    @projects = current_user.projects
    @repositories = current_user.repositories.find(:all, 
      :conditions => ["mainline = ?", false])
    event_project_ids = (@projects.map(&:id) + @repositories.map(&:project_id)).uniq
    @events = Event.paginate(:all, 
      :page => params[:page],
      :conditions => ["events.project_id in (?)", event_project_ids], 
      :order => "events.created_at desc", 
      :include => [:user, :project])    
  end
  
  def about
  end
  
  def faq    
  end
  
end
