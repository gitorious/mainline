# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
module BreadcrumbsHelper
  def render_breadcrumb_starting_from(root)
    result = []
    html = ''
    if current_breadcrumb = root
      until current_breadcrumb.nil?
        result << current_breadcrumb
        current_breadcrumb = current_breadcrumb.breadcrumb_parent
      end
    end
    result.reverse.each do |crumb|
      css_klass = if crumb.respond_to?(:breadcrumb_css_class)
        crumb.breadcrumb_css_class
      else
        crumb.class.to_s.demodulize.downcase
      end
      html << content_tag(:li, breadcrumb_link_to(crumb), :class => css_klass)
    end
    html
  end

  # Renders breadcrumbs starting from +root+
  def breadcrumbs_from(root)
    content_for(:breadcrumbs) do
      render_breadcrumb_starting_from(root)
    end
  end

  def breadcrumb_link_to(an_object)
    url = case an_object
    when Repository
      repo_owner_path(an_object, :project_repository_path, an_object.project, an_object)
    when Project
      project_path(an_object)
    when Group
      group_path(an_object)
    when User
      user_path(an_object)
    when Breadcrumb::Branch
      repo_owner_path(@repository, :project_repository_commits_in_ref_path,
                        @project, @repository, ensplat_path(an_object.title))
    when Breadcrumb::Folder
      tree_path(@ref, an_object.paths)
    when Breadcrumb::Blob
      blob_path(@ref, an_object.path)
    when Breadcrumb::Commit
      commit_path(an_object.sha)
    when Breadcrumb::Wiki
      project_pages_path(an_object.project)
    when Breadcrumb::Page
      project_page_path(an_object.project, an_object.page.to_param)
    when Breadcrumb::Memberships
      group_memberships_path(@group)
    when Membership
      edit_group_membership_path(@group, @membership)
    when Breadcrumb::MergeRequests
      [@owner, @repository, :merge_requests]
    when MergeRequest
      [@owner, @repository, @merge_request]
    when Breadcrumb::Committerships
      [@owner, @repository, :committerships]
    when Committership
      [@owner, @repository, @committership]
    when Breadcrumb::Messages
      messages_path
    when Breadcrumb::ReceivedMessages
      messages_path
    when Breadcrumb::SentMessages
      sent_messages_path
    when Breadcrumb::Aliases
      user_aliases_path
    when Breadcrumb::Keys
      user_keys_path
    when Message
      an_object.new_record? ? new_message_path : message_path(an_object)
    when Breadcrumb::Dashboard
      dashboard_path
    else
      "" # Current path
    end
    link_to(h(an_object.title), url)
  end
end
