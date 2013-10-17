# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

  def render_status_tag_list(statuses, target, active = nil)
    out = "<ul class=\"nav nav-tabs\">"

    if active.nil?
      out << "<li class=\"active\"><a>All</a></li>"
    else
      url = merge_request_link(target)
      out << "<li><a href=\"#{url}\">All</li>"
    end

    statuses.each do |status|
      if active == status.name
        out << "<li class=\"active\"><a>#{status.name}</a></li>"
      else
        out << "<li>#{link_to_status(target, status.name)}</li>"
      end
    end
    out << "</ul>"
    out.html_safe
  end

  def link_to_status(target, status)
    if params[:status].blank? && status == "open"
      link_to_selected_status(target, status)
    elsif params[:status] == status
      link_to_selected_status(target, status)
    else
      link_to_not_selected_status(target, status)
    end
  end

  def link_to_not_selected_status(target, status)
    link_to(h(status.to_s), merge_request_link(target, status))
  end

  def link_to_selected_status(target, status)
    url = merge_request_link(target, status)
    link_to(h(status.to_s), url, :class => "selected")
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
    (%Q{<span class="badge" style="background-color:#{h(status_tag.color)}">} +
     h(status_tag.name) + "</span>").html_safe
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
      ].join("\n").html_safe
    else
      [
       summarize_version_with_single_sha(""),
       summarize_version_with_several_shas(version.short_merge_base,version.affected_commits.last.id_abbrev)
      ].join("\n").html_safe
    end
  end

  def summarize_version_with_single_sha(sha)
    options = {:class => "single_sha"}
    options[:style] = "display: none" if sha.blank?
    content_html = content_tag(:span, 'Showing', :class => 'label') + " " +
      content_tag(:code, sha, :class => 'merge_base')
    content_tag(:div, content_html, options)
  end

  def summarize_version_with_several_shas(first,last)
    options = {:class => "several_shas"}
    options[:style] = "display:none" if last.blank?
    content_html = content_tag(:span, 'Showing', :class => 'label') + " " +
      content_tag(:code, first, :class => 'first') + "-" +
      content_tag(:code, last, :class => 'last')
    content_tag(:div, content_html, options)
  end

  def status_open?(name)
    @statuses ||= {}
    return @statuses[name] if @statuses.key?(name)
    @statuses[name] = MergeRequestStatus.open?(name)
  end

  def version_drop_down(mr, current)
    choices = mr.versions.reverse.select { |v| v != current }.map do |v|
      path = project_repository_merge_request_version_path(mr.project, mr.target_repository, mr, :version => v.version)
      "<li><a href=\"#{path}\">Version #{v.version}</a></li>"
    end

    <<-HTML
      <li class="pull-right dropdown">
        <a href="#" class="dropdown-toggle">Version #{current.version}</a>
        <ul class="dropdown-menu">
          #{choices.join("")}
        </ul>
      </li>
    HTML
  end

  private

  def merge_request_link(target, status = nil)
    args = {}
    args[:status] = status if !status.nil?
    if target.is_a?(Repository)
      return project_repository_merge_requests_path(
        target.project,
        target,
        args)
    end

    project_merge_requests_path(target, args)
  end
end
