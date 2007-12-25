module BrowseHelper
  
  def browse_path
    project_repository_browse_path(@project, @repository)
  end
  
  def tree_path(sha1=nil)
    project_repository_tree_path(@project, @repository, sha1)    
  end
  
  def commit_path(sha1)
    project_repository_commit_path(@project, @repository, sha1)    
  end
  
  def blob_path(sha1, filename)
    project_repository_blob_path(@project, @repository, sha1, filename)    
  end
  
  def diff_path(sha1, other_sha1)
    project_repository_diff_path(@project, @repository, sha1, other_sha1)    
  end
  
end
