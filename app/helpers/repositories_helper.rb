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
  def log_path(objectish = "master", options = {})
    if options.blank? # just to avoid the ? being tacked onto the url
      project_repository_log_path(@project, @repository, objectish)
    else
      project_repository_log_path(@project, @repository, objectish, options)
    end
  end
  
  def commit_path(objectish = "master")
    project_repository_commit_path(@project, @repository, objectish)
  end
  
  def tree_path(treeish = "master", path=[])
    if path.respond_to?(:to_str)
      path = path.split("/")
    end
    project_repository_tree_path(@project, @repository, treeish, path)
  end
  
  def archive_tree_path(treeish = "master")
    project_repository_archive_tree_path(@project, @repository, treeish)
  end
  
  def repository_path(action, sha1=nil)
    project_repository_path(@project, @repository)+"/"+action+"/"+sha1.to_s
  end
  
  def blob_path(sha1, path)
    project_repository_blob_path(@project, @repository, sha1, path)
  end
  
  def raw_blob_path(sha1, path)
    project_repository_raw_blob_path(@project, @repository, sha1, path)
  end
  
  def namespaced_branch?(branchname)
    branchname.include?("/")
  end
end
