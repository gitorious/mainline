class MergeRequestsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_project
  before_filter :find_repository
  before_filter :find_merge_request, :except => [:index, :show, :new, :create]
  before_filter :assert_merge_request_ownership, :except => [:index, :show, :new, :create, :resolve]
  before_filter :assert_merge_request_resolvable, :only => [:resolve]
  
  def index
    @merge_requests = @repository.merge_requests
    @comment_count = @repository.comments.count
    #@proposed_merge_requests = @repository.proposed_merge_requests
  end
  
  def show
    @merge_request = @repository.merge_requests.find(params[:id])
    @commits = @merge_request.target_repository.git.commit_deltas_from(
      @merge_request.source_repository.git, @merge_request.source_branch, @merge_request.target_branch)
  end
  
  def new
    @merge_request = @repository.proposed_merge_requests.new(:user => current_user)
    @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
  end
  
  def create
    @merge_request = @repository.proposed_merge_requests.new(params[:merge_request])
    @merge_request.user = current_user
    respond_to do |format|
      if @merge_request.save
        Event.from_action_name("request merge", current_user, @repository, @merge_request.id)
        format.html {
          flash[:success] = %Q{You sent a merge request to "#{@merge_request.target_repository.name}"}
          redirect_to project_repository_path(@project, @repository) and return
        }
        format.xml { render :xml => @merge_request, :status => :created }
      else
        format.html {
          @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
          render :action => "new"
        }
        format.xml { render :xml => @merge_request.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def resolve
    # TODO: put to change status
    @merge_request.status = params[:merge_request][:status]
    if @merge_request.save
      Event.from_action_name("resolve merge request", current_user, @repository, @merge_request.id)
      flash[:notice] = "The merge request was marked as #{@merge_request.status_string}"
    end
    redirect_to [@project, @repository, @merge_request]      
  end
  
  def edit
    @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
  end
  
  def update
    @merge_request.attributes = params[:merge_request]
    if @merge_request.save
      Event.from_action_name("update merge request", current_user, @repository, @merge_request.id)
      flash[:success] = "Merge request was updated"
      redirect_to [@project, @repository, @merge_request]
    else
      @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
      render :action => "edit"
    end
  end
  
  def destroy
    @merge_request.destroy
    Event.from_action_name("delete merge request", current_user, @repository)
    flash[:success] = "Merge request was retracted"
    redirect_to project_repository_path(@project, @repository)
  end
  
  protected
    def find_repository
      @repository = @project.repositories.find_by_name!(params[:repository_id])
    end
    
    def find_merge_request
      @merge_request = @repository.merge_requests.find(params[:id])
    end
    
    def assert_merge_request_resolvable
      unless @merge_request.resolvable_by?(current_user)
        respond_to do |format|
          flash[:error] = "You're not permitted to resolve this merge request"
          format.html { redirect_to([@project, @repository, @merge_request]) }
          format.xml  { render :text => "You're not permitted to resolve this merge request", :status => :forbidden }
        end
        return
      end
    end
    
    def assert_merge_request_ownership
      if @merge_request.user != current_user
        respond_to do |format|
          flash[:error] = "You're not the owner of this merge request"
          format.html { redirect_to([@project, @repository]) }
          format.xml  { render :text => "You're not the owner of this merge request", :status => :forbidden }
        end
        return
      end
    end
  
end
