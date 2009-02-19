#--
#   Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2009 Marius Mathiesen <marius.mathiesen@gmail.com>
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

class MergeRequestsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_repository_owner
  before_filter :find_repository
  before_filter :find_merge_request,  
    :except => [:index, :show, :new, :create, :commit_list, :target_branches]
  before_filter :assert_merge_request_ownership, 
    :except => [:index, :show, :new, :create, :resolve, :commit_list, :target_branches]
  before_filter :assert_merge_request_resolvable, :only => [:resolve]
  
  def index
    @merge_requests = @repository.merge_requests
    @comment_count = @repository.comments.count
    #@proposed_merge_requests = @repository.proposed_merge_requests
  end
  
  def commit_list
    @merge_request = @repository.proposed_merge_requests.new(params[:merge_request])
    @merge_request.user = current_user
    @commits = @merge_request.commits_to_be_merged
    render :partial => "commit_list", :layout => false
  end
  
  def target_branches
    @merge_request = @repository.proposed_merge_requests.new(params[:merge_request])
    @merge_request.user = current_user
    @target_branches = @merge_request.target_branches_for_selection
    render :partial => "target_branches", :layout => false
  end
  
  def show
    @merge_request = @repository.merge_requests.find(params[:id])
    @commits = @merge_request.commits_to_be_merged
  end
  
  def new
    @merge_request = @repository.proposed_merge_requests.new
    @merge_request.user = current_user
    @repositories = @owner.repositories.find(:all, :conditions => ["id != ?", @repository.id])
    if first = @repositories.find{|r| r.mainline? } || @repositories.first
      @merge_request.target_repository_id = first.id
    end
    get_branches_and_commits_for_selection
  end
  
  def create
    @merge_request = @repository.proposed_merge_requests.new(params[:merge_request])
    @merge_request.user = current_user
    respond_to do |format|
      if @merge_request.save
        @owner.create_event(Action::REQUEST_MERGE, @merge_request, current_user)
        format.html {
          flash[:success] = I18n.t "merge_requests_controller.create_success", :name => @merge_request.target_repository.name
          redirect_to [@owner, @repository] and return
        }
        format.xml { render :xml => @merge_request, :status => :created }
      else
        format.html {
          @repositories = @owner.repositories.find(:all, :conditions => ["id != ?", @repository.id])
          get_branches_and_commits_for_selection
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
      @owner.create_event(Action::RESOLVE_MERGE_REQUEST, @merge_request, current_user)
      flash[:notice] = I18n.t "merge_requests_controller.resolve_notice", :status => @merge_request.status_string
    end
    redirect_to [@owner, @repository, @merge_request]      
  end
  
  def edit
    @repositories = @owner.repositories.find(:all, :conditions => ["id != ?", @repository.id])
    get_branches_and_commits_for_selection
  end
  
  def update
    @merge_request.attributes = params[:merge_request]
    if @merge_request.save
      @owner.create_event(Action::UPDATE_MERGE_REQUEST, @merge_request, current_user)
      flash[:success] = I18n.t "merge_requests_controller.update_success"
      redirect_to [@owner, @repository, @merge_request]
    else
      @repositories = @owner.repositories.find(:all, :conditions => ["id != ?", @repository.id])
      get_branches_and_commits_for_selection
      render :action => "edit"
    end
  end
  
  def destroy
    @merge_request.destroy
    @owner.create_event(Action::DELETE_MERGE_REQUEST, @repository, current_user)
    flash[:success] = I18n.t "merge_requests_controller.destroy_success"
    redirect_to [@owner, @repository]
  end
  
  protected    
    def find_repository
      @repository = @owner.repositories.find_by_name!(params[:repository_id])
    end
    
    def find_merge_request
      @merge_request = @repository.merge_requests.find(params[:id])
    end
    
    def assert_merge_request_resolvable
      unless @merge_request.resolvable_by?(current_user)
        respond_to do |format|
          flash[:error] = I18n.t "merge_requests_controller.assert_resolvable_error"
          format.html { redirect_to([@owner, @repository, @merge_request]) }
          format.xml  { render :text => I18n.t( "merge_requests_controller.assert_resolvable_error"), :status => :forbidden }
        end
        return
      end
    end
    
    def assert_merge_request_ownership
      if @merge_request.user != current_user
        respond_to do |format|
          flash[:error] = I18n.t "merge_requests_controller.assert_ownership_error"
          format.html { redirect_to([@owner, @repository]) }
          format.xml  { render :text => I18n.t("merge_requests_controller.assert_ownership_error"), :status => :forbidden }
        end
        return
      end
    end
    
    def get_branches_and_commits_for_selection
      @source_branches = @repository.git.branches
      @target_branches = @merge_request.target_branches_for_selection
      @commits = @merge_request.commits_for_selection
    end
  
end
