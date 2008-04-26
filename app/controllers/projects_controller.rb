class ProjectsController < ApplicationController  
  before_filter :login_required, :only => [:create, :update, :destroy, :new]
  before_filter :require_user_has_ssh_keys, :only => [:new, :create]
  
  def index
    @projects = Project.paginate(:all, :order => "projects.created_at desc", 
                  :page => params[:page], :include => [:tags, { :repositories => :project } ])
    
    @atom_auto_discovery_url = formatted_projects_path(:atom)
    respond_to do |format|
      format.html { @tags = Project.top_tags }
      format.xml  { render :xml => @projects }
      format.atom { }
    end
  end
  
  def category
    tags = params[:id].to_s.gsub(/,\ ?/, " ")
    @projects = Project.paginate_by_tag(tags, :order => 'created_at desc', 
                  :page => params[:page])
    @atom_auto_discovery_url = formatted_projects_category_path(params[:id], :atom)
    respond_to do |format|
      format.html do
        @tags = Project.tag_counts
        render :action => "index"
      end
      format.xml  { render :xml => @projects }
      format.atom { render :action => "index"}
    end
  end
  
  def show
    @project = Project.find_by_slug!(params[:id], :include => [:repositories])
    @mainline_repository = @project.mainline_repository
    @repositories = @project.repository_clones
    @events = @project.events.paginate(:all, :page => params[:page], 
      :order => "created_at desc", :include => [:user, :project])
    
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
      @project.create_event(Action::CREATE_PROJECT, @project, current_user)
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
    if @project.user != current_user
      flash[:error] = "You're not the owner of this project"
      redirect_to(project_path(@project)) and return
    end
    @project.attributes = params[:project]
    if @project.save
      @project.create_event(Action::UPDATE_PROJECT, @project, current_user)
      redirect_to project_path(@project)
    else
      render :action => 'new'
    end
  end
  
  def confirm_delete
    @project = Project.find_by_slug!(params[:id])
  end
  
  def destroy
    @project = Project.find_by_slug!(params[:id])
    if @project.can_be_deleted_by?(current_user)
      project_title = @project.title
      @project.destroy
      #current_user.create_event(Action::DELETE_PROJECT, nil, project_title)
    else
      flash[:error] = "You're not the owner of this project, or the project has clones"
    end
    redirect_to projects_path
  end
end