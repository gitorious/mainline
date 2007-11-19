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
      @repository.committers << @committer
      redirect_to [@repository.project, @repository]
    else
      flash[:error] = "Could not find user by that name"
    end
  end
  
  def destroy
    @permission = @repository.permissions.find(params[:id])
    if @permission.destroy
      flash[:success] = "User removed from repository"
    end    
    redirect_to [@repository.project, @repository]
  end
  
  private
    def find_repository
      @repository = Repository.find(params[:repository_id])
    end
end
