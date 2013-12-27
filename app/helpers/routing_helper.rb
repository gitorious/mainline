# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 August Lilleaas <augustlilleaas@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2009 Bill Marquette <bill.marquette@gmail.com>
#   Copyright (C) 2010 Christian Johansen <christian@shortcut.no>
#
#   Copyright (C) 2011 Gitorious AS
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

# These helpers are used both in views and some controllers
#
module RoutingHelper
  # turns ["foo", "bar"] route globbing parameters into "foo/bar"
  # Note that while the path components will be uri unescaped, any
  # '+' will be preserved
  def desplat_path(*paths)
    # we temporarily swap the + out with a magic byte, so
    # filenames/branches with +'s won't get unescaped to a space
    paths.flatten.compact.map do |p|
      p.force_encoding('ascii-8bit') if p.respond_to?(:force_encoding)
      CGI.unescape(p.gsub("+", "\001")).gsub("\001", '+')
    end.join("/")
  end

  # turns "foo/bar" into ["foo", "bar"] for route globbing
  def ensplat_path(path)
    path.split("/").select{|p| !p.blank? }
  end

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

  def tree_path(treeish = "master")
    tree_entry_url(@repository.slug, treeish, '')
  end

  def repository_path(action, sha1=nil)
    project_repository_path(@project, @repository) + "/" + action + "/" + sha1.to_s
  end

  def blob_path(shaish, path)
    project_repository_blob_path(@project, @repository, branch_with_tree(shaish, path))
  end

  def raw_blob_path(shaish, path)
    project_repository_raw_blob_path(@project, @repository, branch_with_tree(shaish, path))
  end

  def blob_history_path(shaish, path)
    project_repository_blob_history_path(@project, @repository, branch_with_tree(shaish, path))
  end

  def file_path(repository, filename, head = "master")
    project_repository_blob_path(repository.project, repository, branch_with_tree(head, filename))
  end

  def new_polymorphic_comment_path(parent, comment)
    return [@project, @repository, parent, comment] if parent
    [@project, @repository, comment]
  end

  def select_version_url(merge_request)
    url_for(polymorphic_path([:version, merge_request.target_repository.project,
                              merge_request.target_repository, merge_request]))
  end
end
