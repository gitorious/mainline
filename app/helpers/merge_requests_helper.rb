# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

module MergeRequestsHelper
  include MergeRequestVersionsHelper
  def render_status_tag_list(status_tags, repository)
    project_statuses = repository.project.merge_request_statuses
    
    out = '<ul class="horizontal">'
    open_tags = project_statuses.select{|s| s.open? }
    out << "<li>Open:</li>" unless open_tags.blank?
    open_tags.each do |status|
      out << "<li>#{link_to_status(repository, status.name)}</li>"
    end
    out << '</ul><div class="clear"></div>'

    out << '<ul class="horizontal">'
    closed_tags = project_statuses.select{|s| s.closed? }
    out << "<li>Closed:</li>" unless closed_tags.blank?
    closed_tags.each do |status|
      out << "<li>#{link_to_status(repository, status.name)}</li>"
    end
    out << '</ul><div class="clear"></div>'

    out << '<ul class="horizontal">'
    orphaned_tags = status_tags.select do |s|
      !project_statuses.map{|s| s.name.downcase}.include?(s.to_s.downcase)
    end
    out << "<li>Other:</li>" unless orphaned_tags.blank?
    orphaned_tags.each do |status|
      out << "<li class=foo>#{link_to_status(repository, status)}</li>"
    end
    out << "</ul>"
    out
  end
  
  def link_to_status(repository, status)
    if params[:status].blank? && status == "open"
      link_to_selected_status(repository, status)
    elsif params[:status] == status
      link_to_selected_status(repository, status)
    else
      link_to_not_selected_status(repository, status)
    end
  end
  
  def link_to_not_selected_status(repository, status)
    link_to(h(status.to_s), repo_owner_path(repository, 
        :project_repository_merge_requests_path, repository.project,
        repository, {:status => status}))
  end
  
  def link_to_selected_status(repository, status)
    link_to(h(status.to_s), repo_owner_path(repository, 
        :project_repository_merge_requests_path, repository.project,
        repository, {:status => status}), {:class => "selected"})
  end

  # ul data-merge-request-version-url=""
  def commit_diff_url(mr_version)
    url_for(polymorphic_path([
                             @merge_request.target_repository.project,
                             @merge_request.target_repository,
                             @merge_request,
                             mr_version
            ]))
  end


  def merge_base_link(version)
    inline_sha_link(version.merge_base_sha[0..6], version.merge_base_sha)
  end
  
  # a href="#commit_<sha>" id="commit_<sha>" data-commit-sha="sha"
  def inline_commit_link(commit)
    inline_sha_link(commit.id_abbrev, commit.id)
  end

  def inline_sha_link(label, sha)
    content_tag(:a, label, {:"data-commit-sha" => sha, :class => "clickable_commit"})
  end

  def colorized_status(status_tag)
    %Q{<span style="color:#{h(status_tag.color)}">} + h(status_tag.name) + "</span>"
  end
end
