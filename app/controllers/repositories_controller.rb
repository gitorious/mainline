#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class RepositoriesController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :writable_by]
  before_filter :find_repository_owner
  before_filter :require_adminship, :only => [:edit, :update, :new, :create, :edit, :update, :committers]
  before_filter :require_user_has_ssh_keys, :only => [:clone, :create_clone]
  before_filter :only_projects_can_add_new_repositories, :only => [:new, :create]
  skip_before_filter :public_and_logged_in, :only => [:writable_by]
  renders_in_site_specific_context :except => :writable_by
  
  def index
    @repositories = @owner.repositories.find(:all, :include => [:user, :events, :project])
  end
    
  def show
    @repository = @owner.repositories.find_by_name!(params[:id])
    @events = @repository.events.top.paginate(:all, :page => params[:page], 
      :order => "created_at desc")
    
    @atom_auto_discovery_url = project_repository_path(@owner, @repository, :format => :atom)
    response.headers['Refresh'] = "5" unless @repository.ready
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @repository }
      format.atom {  }
    end
  end
  
  def new
    @repository = @project.repositories.new
    @repository.kind = Repository::KIND_PROJECT_REPO
    @repository.owner = @project.owner
    if @project.repositories.mainlines.count == 0
      @repository.name = @project.slug
    end
  end
  
  def create
    @repository = @project.repositories.new(params[:repository])
    @repository.kind = Repository::KIND_PROJECT_REPO
    @repository.owner = @project.owner
    @repository.user = current_user
    
    if @repository.save
      flash[:success] = I18n.t("repositories_controller.create_success")
      redirect_to [@repository.project_or_owner, @repository]
    else
      render :action => "new"
    end
  end
  
  undef_method :clone
  
  def clone
    @repository_to_clone = @owner.repositories.find_by_name!(params[:id])
    unless @repository_to_clone.has_commits?
      flash[:error] = I18n.t "repositories_controller.new_clone_error"
      redirect_to [@owner, @repository_to_clone]
      return
    end
    @repository = Repository.new_by_cloning(@repository_to_clone, current_user.login)
  end
  
  def create_clone
    @repository_to_clone = @owner.repositories.find_by_name!(params[:id])
    unless @repository_to_clone.has_commits?
      respond_to do |format|
        format.html do
          flash[:error] = I18n.t "repositories_controller.create_clone_error"
          redirect_to [@owner, @repository_to_clone]
        end
        format.xml do 
          render :text => I18n.t("repositories_controller.create_clone_error"), 
            :location => [@owner, @repository_to_clone], :status => :unprocessable_entity
        end
      end
      return
    end

    @repository = Repository.new_by_cloning(@repository_to_clone)
    @repository.name = params[:repository][:name]
    @repository.user = current_user
    case params[:repository][:owner_type]
    when "User"
      @repository.owner = current_user
      @repository.kind = Repository::KIND_USER_REPO
    when "Group"
      @repository.owner = current_user.groups.find(params[:repository][:owner_id])
      @repository.kind = Repository::KIND_TEAM_REPO
    end
    
    respond_to do |format|
      if @repository.save
        @owner.create_event(Action::CLONE_REPOSITORY, @repository, current_user, @repository_to_clone.id)
        
        location = repo_owner_path(@repository, :project_repository_path, @owner, @repository)
        format.html { redirect_to location }
        format.xml  { render :xml => @repository, :status => :created, :location => location }        
      else
        format.html { render :action => "clone" }
        format.xml  { render :xml => @repository.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @repository = @owner.repositories.find_by_name!(params[:id])
    @groups = current_user.groups
  end
  
  def update
    @repository = @owner.repositories.find_by_name!(params[:id])
    @groups = current_user.groups
    prior_description = @repository.description
    @repository.description = params[:repository][:description]    
    # change group, if requested
    Repository.transaction do
      unless params[:repository][:owner_id].blank?
        @repository.change_owner_to!(current_user.groups.find(params[:repository][:owner_id]))
      end
      # events.create(:action => action_id, :target => target, :user => user,
      #               :body => body, :data => data, :created_at => date)

      @repository.save!
      if @repository.description != prior_description
        @repository.events.create!(:action => Action::UPDATE_REPOSITORY, :user => current_user, :project => @repository.project, :body => 'Changed the repository description')
      end
      flash[:success] = "Repository updated"
      redirect_to [@repository.project_or_owner, @repository]
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    render :action => "edit"
  end
  
  # Used internally to check write permissions by gitorious
  def writable_by
    # if @project
    #   @repository = @project.repositories.find_by_name!(params[:id])
    # else
    #   @repository = @owner.repositories.find_by_name!(params[:id])
    # end
    @repository = @owner.repositories.find_by_name!(params[:id])
    user = User.find_by_login(params[:username])
    if user && user.can_write_to?(@repository)
      render :text => "true #{@repository.real_gitdir}"
    else
      render :text => "false nil"
    end
  end
  
  def confirm_delete
    @repository = @owner.repositories.find_by_name!(params[:id])
  end
  
  def destroy
    @repository = @owner.repositories.find_by_name!(params[:id])
    if @repository.can_be_deleted_by?(current_user)
      repo_name = @repository.name
      flash[:notice] = I18n.t "repositories_controller.destroy_notice"
      @repository.destroy
      @repository.project.create_event(Action::DELETE_REPOSITORY, @owner, 
                                        current_user, repo_name)
    else
      flash[:error] = I18n.t "repositories_controller.destroy_error"
    end
    redirect_to @owner
  end
  
  private    
    def require_adminship
      unless @owner.admin?(current_user)
        respond_to do |format|
          format.html { 
            flash[:error] = I18n.t "repositories_controller.adminship_error"
            redirect_to(@owner) 
          }
          format.xml  { 
            render :text => I18n.t( "repositories_controller.adminship_error"), 
                    :status => :forbidden 
          }
        end
        return
      end
    end
    
    def only_projects_can_add_new_repositories
      if !@owner.is_a?(Project)
        respond_to do |format|
          format.html { 
            flash[:error] = I18n.t("repositories_controller.only_projects_create_new_error")
            redirect_to(@owner) 
          }
          format.xml  { 
            render :text => I18n.t( "repositories_controller.only_projects_create_new_error"), 
                    :status => :forbidden 
          }
        end
        return
      end
    end
end
