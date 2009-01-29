#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

module RepositoriesHelper  
  include BreadcrumbsHelper
  def log_path(objectish = "master", options = {})
    objectish = ensplat_path(objectish)
    if options.blank? # just to avoid the ? being tacked onto the url
      project_repository_commits_in_ref_path(@project, @repository, objectish)
    else
      project_repository_commits_in_ref_path(@project, @repository, objectish, options)
    end
  end
  
  def commit_path(objectish = "master")
    project_repository_commit_path(@project, @repository, objectish)
  end
  
  def tree_path(treeish = "master", path = [])
    if path.respond_to?(:to_str)
      path = path.split("/")
    end
    project_repository_tree_path(@project, @repository, branch_with_tree(treeish, path))
  end
  
  def archive_tree_path(treeish = "master", format = "tar.gz")
    project_repository_archive_tree_path(@project, @repository, treeish, format)
  end
  
  def repository_path(action, sha1=nil)
    project_repository_path(@project, @repository)+"/"+action+"/"+sha1.to_s
  end
  
  def blob_path(shaish, path)
    project_repository_blob_path(@project, @repository, branch_with_tree(shaish, path))
  end
  
  def raw_blob_path(shaish, path)
    project_repository_raw_blob_path(@project, @repository, branch_with_tree(shaish, path))
  end
  
  def namespaced_branch?(branchname)
    branchname.include?("/")
  end
  
  def edit_or_show_group_text
    if @repository.owner.admin?(current_user) 
      t("views.repos.edit_group") 
    else
      t("views.repos.show_group")
    end
  end
end
