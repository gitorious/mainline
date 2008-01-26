class CommentsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :find_project
  before_filter :find_repository
  
  def index
    @comments = @repository.comments.find(:all, :include => :user)
    @atom_auto_discovery_url = formatted_project_repository_comments_path(@project, @repository, :atom)
    respond_to do |format|
      format.html { }
      format.atom { }
    end
  end
  
  def commit
    @git = Git.bare(@repository.full_repository_path)
    @commit = @git.gcommit(params[:sha])
    @comments = @repository.comments.find_all_by_sha1(params[:sha], :include => :user)
  end
  
  def new
    @comment = @repository.comments.new
  end
  
  def create
    @comment = @repository.comments.new(params[:comment])
    @comment.user = current_user
    @comment.project = @project
    respond_to do |format|
      if @comment.save
        format.html do
          flash[:success] = "Your comment was added"
          redirect_to project_repository_comments_path(@project, @repository)
        end
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  protected
    def find_repository
      @repository = @project.repositories.find_by_name!(params[:repository_id])
    end
end
