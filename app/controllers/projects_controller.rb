class ProjectsController < ApplicationController  
  before_filter :login_required, :only => [:create, :update, :destroy, :new]
  before_filter :require_user_has_ssh_keys, :only => [:new, :create]
  
  def index
    @projects = Project.paginate(:all, :order => "created_at desc", 
                  :page => params[:page])
    respond_to do |format|
      format.html { @tags = Project.tag_counts }
      format.xml  { render :xml => @projects }
    end
  end
  
  def category
    tags = params[:id].to_s.gsub(/,\ ?/, " ")
    @projects = Project.paginate_by_tag(tags, :order => 'created_at desc', 
                  :page => params[:page])

    respond_to do |format|
      format.html do
        @tags = Project.tag_counts
        render :action => "index"
      end
      format.xml { render :xml => @projects }
    end
  end
  
  def show
    @project = Project.find_by_slug!(params[:id])
    @repositories = @project.repositories
    
    respond_to do |format|
      format.html
      format.xml { render :xml => @project }
    end
  end
  
  def new
  end
  
  def create
    @project = Project.new(params[:project])
    @project.user = current_user
    if @project.save
      redirect_to projects_path
    else
      render :action => 'new'
    end
  end
  
  def edit
    @project = Project.find_by_slug!(params[:id])
  end
  
  def update
    @project = Project.find_by_slug!(params[:id])
    @project.attributes = params[:project]
    if @project.save
      redirect_to project_path(@project)
    else
      render :action => 'new'
    end
  end
  
  def destroy
    @project = Project.find_by_slug!(params[:id])
    @project.destroy
    redirect_to projects_path
  end
end