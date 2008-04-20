class CommittersController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :destroy, :list]
  before_filter :find_project
  before_filter :find_repository, 
    :only => [:show, :new, :create, :edit, :update, :destroy, :list]
    
  def new
    @committer = User.new
  end
  
  def create
    @committer = User.find_by_login(params[:user][:login])
    unless @committer
      flash[:error] = "Could not find user by that name"
      respond_to do |format|
        format.html { redirect_to(new_committer_url(@repository.project, @repository)) }
        format.xml  { render :text => "Could not a find user by that name", :status => :not_found }
      end
      return
    end

    respond_to do |format|
      if @repository.add_committer(@committer)
        @committership = @repository.committerships.find_by_user_id(@committer.id)
        @project.create_event(Action::ADD_COMMITTER, @committership, current_user)
        format.html { redirect_to([@repository.project, @repository]) }
        format.xml do 
          render :xml => @committer
        end
      else
        flash[:error] = "Could not add user or user is already a committer"
        format.html { redirect_to(new_committer_url(@repository.project, @repository)) }
        format.xml  { render :text => "Could not add user or user is already a committer", :status => :not_found }
      end
    end
  end
  
  def destroy
    @committership = @repository.committerships.find_by_user_id(params[:id])
    
    respond_to do |format|
      if @committership.destroy
        @project.create_event(Action::REMOVE_COMMITTER, @repository, current_user, params[:id])
        flash[:success] = "User removed from repository"
        format.html { redirect_to [@repository.project, @repository] }
        format.xml  { render :nothing, :status => :ok }
      else
        flash[:error] = "Could not remove user from repository"
        format.html { redirect_to [@repository.project, @repository] }
        format.xml  { render :nothing, :status => :unprocessable_entity }
      end    
      
    end
  end
  
  def list
    @committers = @repository.committers
    respond_to do |format|
      format.xml { render :xml => @committers }
    end
  end
  
  def auto_complete_for_user_login
    login = params[:user][:login]
    @users = User.find(:all, 
      :conditions => [ 'LOWER(login) LIKE ?', '%' + login.downcase + '%' ],
      :limit => 10)
    render :layout => false
  end
  
  private
    def find_repository
      @repository = @project.repositories.find_by_name!(params[:repository_id])
      unless @repository.user == current_user
        flash[:error] = "You're not the owner of this repository"
        redirect_to [@repository.project, @repository]
      end
    end
end
