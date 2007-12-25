class CommittersController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :destroy]
  before_filter :find_repository, 
    :only => [:show, :new, :create, :edit, :update, :destroy]
    
  def new
    @committer = User.new
  end
  
  def create
    @committer = User.find_by_login(params[:user][:login])
    unless @committer
      flash[:error] = "Could not find user by that name"
      respond_to do |format|
        format.html { redirect_to(new_committer_url(@repository.project, @repository)) }
        format.xml  { render :text => "Could not a find user by that name", :Status => :not_found }
      end
      return
    end

    if @repository.add_committer(@committer)
      respond_to do |format|
        format.html { redirect_to([@repository.project, @repository]) }
        format.xml do 
          render :nothing, :status => :created, 
            :location => project_repository_path(@repository.project, @repository)
        end
      end
    end
  end
  
  def destroy
    @committership = @repository.committerships.find_by_user_id(params[:id])
    
    respond_to do |format|
      if @committership.destroy
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
  
  def auto_complete_for_user_login
    #@users = User.find(:all, :conditions => ["login ilike ?", params[:user][:login]])
    login = params[:user][:login]
    @users = User.find(:all, 
      :conditions => [ 'LOWER(login) LIKE ?', '%' + login.downcase + '%' ])
    logger.debug @users.inspect
    render :inline => "<%= auto_complete_result(@users, 'login') %>"
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
