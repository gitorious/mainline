class SiteController < ApplicationController
  before_filter :login_required, :only => [:dashboard]
  
  def index
    @tags = Project.tag_counts
    @projects = Project.find(:all, :limit => 5, :order => "id desc")
  end
  
  def dashboard
    @projects = current_user.projects
    project_ids = @projects.map(&:id)
    @recent_comments = Comment.find(:all, :limit => 10,
      :conditions => ["comments.project_id in (?)", project_ids], 
      :order => "comments.created_at desc", :include => [:user, :repository])
    @repository_clones = @projects.map(&:repository_clones).flatten
    # @repository_clones = Repository.find(:all, 
    #   :conditions => ["project_id in (?) and mainline = ?", project_ids, false])
  end
  
  def about
  end
  
  def faq    
  end
  
end
