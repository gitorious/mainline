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
  
  def download_archive_links(repository)
    # FIXME: should just use the polymorphic path instead
    link_meth = case @owner
    when Project
      method(:project_repository_archive_tree_path)
    when Group
      method(:group_repository_archive_tree_path)
    when User
      method(:user_repository_archive_tree_path)
    end
    gz_link = link_meth.call(@owner, repository, repository.head_candidate.name, "tar.gz")
    zip_link = link_meth.call(@owner, repository, repository.head_candidate.name, "zip")
    content_tag(:li, link_to("Download as .tar.gz", gz_link), :class => "gz") + 
    content_tag(:li, link_to("Download as .zip", zip_link), :class => "zip") 
  end
  
  def toggle_more_repository_urls(repository)
    js = <<-eos
    <script type="text/javascript" charset="utf-8">
      $('repo-#{repository.id}-url-toggle').observe('click', function(event) {
        $('repo-#{repository.id}-http-url').toggle();
        if ($('repo-#{repository.id}-push-url'))
          $('repo-#{repository.id}-push-url').toggle();
        Event.stop(event);
      });
    </script>
    eos
    if logged_in? && current_user.can_write_to?(repository)
      text = "Show HTTP clone url &amp; SSH push url"
    else
      text = "Show HTTP clone url"
    end
    img = image_tag("silk/database_key.png", :alt => text, :title => text)
    content_tag(:a, img, :href => "#more-urls", 
                          :id => "repo-#{repository.id}-url-toggle",
                          :class => "hint") + js
  end
end
