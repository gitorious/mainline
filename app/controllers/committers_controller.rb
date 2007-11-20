class CommittersController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :destroy]
  before_filter :find_repository, 
    :only => [:show, :new, :create, :edit, :update, :destroy]
    
  def new
    @committer = User.new
  end
  
  def create
    @committer = User.find_by_login(params[:user][:login])
    if @committer && !@repository.permissions.find_by_user_id(@committer.id)
      @repository.committers << @committer
      redirect_to [@repository.project, @repository]
    else
      flash[:error] = "Could not find user by that name"
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
      @repository = Repository.find(params[:repository_id])
      unless @repository.user == current_user
        flash[:error] = "You're not the owner of this repository"
        redirect_to [@repository.project, @repository]
      end
    end
end
