class TreesController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  
  def index
    redirect_to(project_repository_tree_path(@project, @repository, 
        @repository.head_candidate.name, []))
  end
  
  def show
    @git = @repository.git
    @commit = @git.commit(params[:id])
    unless @commit
      redirect_to project_repository_tree_path(@project, @repository, "HEAD", params[:path])
      return
    end
    path = params[:path].blank? ? [] : ["#{params[:path].join("/")}/"] # FIXME: meh, this sux
    @tree = @git.tree(@commit.tree.id, path)
  end
  
  def archive
    @git = @repository.git    
    @commit = @git.commit(params[:id])
    
    if @commit
      prefix = "#{@project.slug}-#{@repository.name}"
      data = @git.archive_tar_gz(params[:id], prefix + "/")      
      send_data(data, :type => 'application/x-gzip', 
        :filename => "#{prefix}.tar.gz") 
    else
      flash[:error] = "The given repository or sha is invalid"
      redirect_to project_repository_path(@project, @repository) and return
    end
  end
end
