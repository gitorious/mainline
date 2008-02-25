class MergeRequestsController < ApplicationController
  before_filter :login_required
  before_filter :find_project
  before_filter :find_repository
  before_filter :find_merge_request, :except => [:new, :create]
  before_filter :assert_merge_request_ownership, :except => [:new, :create]
  
  def new
    @merge_request = @repository.proposed_merge_requests.new(:user => current_user)
    @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
  end
  
  def create
    @merge_request = @repository.proposed_merge_requests.new(params[:merge_request])
    @merge_request.user = current_user
    if @merge_request.save
      flash[:success] = "Your sent a merge request to #{@merge_request.target_repository.name}"
      redirect_to project_repository_path(@project, @repository) and return
    else
      @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
      render :action => "new"
    end
  end
  
  def edit
    @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
  end
  
  def update
    @merge_request.attributes = params[:merge_request]
    if @merge_request.save
      flash[:success] = "Merge request was updated"
      redirect_to merge_request_path(@project, @repository, @merge_request)
    else
      @repositories = @project.repositories.find(:all, :conditions => ["id != ?", @repository.id])
      render :action => "edit"
    end
  end
  
  def destroy
    @merge_request.destroy
    flash[:success] = "Merge request was retracted"
    redirect_to project_repository_path(@project, @repository)
  end
  
  protected
    def find_repository
      @repository = @project.repositories.find_by_name!(params[:repository_id])
    end
    
    def find_merge_request
      @merge_request = @repository.proposed_merge_requests.find(params[:id])
    end
    
    def assert_merge_request_ownership
      if @merge_request.user != current_user
        respond_to do |format|
          flash[:error] = "You're not the owner of this merge request"
          format.html { redirect_to(project_repository_path(@project, @repository)) }
          format.xml  { render :text => "You're not the owner of this merge request", :status => :forbidden }
        end
        return
      end
    end
  
end
