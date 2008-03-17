class BlobsController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  

  def show
    @git = @repository.git
    @commit = @git.commit(params[:id])
    unless @commit
      redirect_to project_repository_blob_path(@project, @repository, "HEAD", params[:path])
      return
    end
    @blob = @git.tree(@commit.tree.id, ["#{params[:path].join("/")}"]).contents.first
    render_not_found and return unless @blob
    unless @blob.respond_to?(:data) # it's a tree
      redirect_to project_repository_tree_path(@project, @repository, @commit.id, params[:path])
    end
  end

  def raw
    @git = @repository.git
    @commit = @git.commit(params[:id])
    unless @commit
      redirect_to project_repository_raw_blob_path(@project, @repository, "HEAD", params[:path])
      return
    end
    @blob = @git.tree(@commit.tree.id, ["#{params[:path].join("/")}"]).contents.first
    render_not_found and return unless @blob
    if @blob.size > 500.kilobytes
      flash[:error] = "Blob is too big. Clone the repository locally to see it"
      redirect_to project_repository_path(@project, @repository) and return
    end
    render :text => @blob.data, :content_type => @blob.mime_type
  end
  
  # def text
  # end
end
