class CommittersController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :destroy]
  before_filter :find_repository, 
    :only => [:show, :new, :create, :edit, :update, :destroy]
    
  def new
    @committer = User.new
  end
  
  def create
    @committer = User.find_by_login(params[:user][:login])
    if @committer
      if !@repository.permissions.find_by_user_id(@committer.id)
        @repository.committers << @committer
        redirect_to([@repository.project, @repository]) and return
      else
        flash[:error] = "User is already a committer"
        redirect_to(new_committer_url(@repository.project, @repository)) and return
      end
    else
      flash[:error] = "Could not find user by that name"
      redirect_to(new_committer_url(@repository.project, @repository))
    end
  end
  
  def destroy
    @permission = @repository.permissions.find_by_user_id(params[:id])
    if @permission.destroy
      flash[:success] = "User removed from repository"
    end    
    redirect_to [@repository.project, @repository]
  end
  
  private
    def find_repository
      @repository = Repository.find_by_name!(params[:repository_id])
      unless @repository.user == current_user
        flash[:error] = "You're not the owner of this repository"
        redirect_to [@repository.project, @repository]
      end
    end
end
