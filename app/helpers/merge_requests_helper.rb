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
  include CommentsHelper

  def render_status_tag_list(status_tags, repository)
    project_statuses = repository.project.merge_request_statuses
    
    out = '<ul class="horizontal">'
    open_tags = project_statuses.select{|s| s.open? }
    out << "<li><strong>Open:</strong></li>" unless open_tags.blank?
    open_tags.each do |status|
      out << "<li>#{link_to_status(repository, status.name)}</li>"
    end
    out << '</ul>'

    out << '<ul class="horizontal">'
    closed_tags = project_statuses.select{|s| s.closed? }
    out << "<li><strong>Closed:</strong></li>" unless closed_tags.blank?
    closed_tags.each do |status|
      out << "<li>#{link_to_status(repository, status.name)}</li>"
    end
    out << '</ul>'

    out << '<ul class="horizontal">'
    orphaned_tags = status_tags.select do |status|
      !project_statuses.map{|s| s.name.downcase }.include?(status.to_s.downcase)
    end
    out << "<li><strong>Other:</strong></li>" unless orphaned_tags.blank?
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

  def merge_base_link(version)
    version.merge_base_sha[0..6]
  end
  
  # a href="#commit_<sha>" id="commit_<sha>" data-commit-sha="sha"
  def inline_commit_link(commit)
    inline_sha_link(commit.id_abbrev, commit.id)
  end

  def inline_sha_link(label, sha)
    content_tag(:a, label, {
        "data-commit-sha" => sha,
        :class => "clickable_commit",
        :href => "#"
      })
  end

  def colorized_status(status_tag)
    return "" unless status_tag
    %Q{<span style="color:#{h(status_tag.color)}">} + h(status_tag.name) + "</span>"
  end

  # By some arbitarily random standard, does this +version+ contain many commits?
  def many_commits?(version)
    version.affected_commits.length > 7
  end

  # TODO: Add a button to display the status. git cherry takes way too long for us to wait
  # for it to perform
  def commit_css_class(merge_request, commit)
    "unmerged"
  end

  def summarize_version(version)
    if version.affected_commits.blank?
      [
       summarize_version_with_single_sha(version.short_merge_base),
       summarize_version_with_several_shas("","")
      ].join("\n")
    else
      [
       summarize_version_with_single_sha(""),
       summarize_version_with_several_shas(version.short_merge_base,version.affected_commits.last.id_abbrev)
      ].join("\n")
    end
  end

  def summarize_version_with_single_sha(sha)
    options = {:class => "single_sha"}
    options[:style] = "display: none" if sha.blank?
    content_html = content_tag(:span, 'Showing', :class => 'label') + " " +
      content_tag(:code, sha, :class => 'merge_base')
    content_tag(:div, "#{content_html}", options)
  end

  def summarize_version_with_several_shas(first,last)
    options = {:class => "several_shas"}
    options[:style] = "display:none" if last.blank?
    content_html = content_tag(:span, 'Showing', :class => 'label') + " " +
      content_tag(:code, first, :class => 'first') + "-" +
      content_tag(:code, last, :class => 'last')
    content_tag(:div, "#{content_html}", options)
  end

end
