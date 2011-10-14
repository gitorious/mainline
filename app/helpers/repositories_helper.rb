# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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

module RepositoriesHelper
  include FavoritesHelper

  def blob_blame_path(shaish, path)
    repo_owner_path(@repository, :project_repository_blame_path, @project, @repository, branch_with_tree(shaish, path))
  end

  def namespaced_branch?(branchname)
    branchname.include?("/")
  end

  def edit_or_show_group_text
    if @repository.admin?(current_user)
      t("views.repos.edit_group")
    else
      t("views.repos.show_group")
    end
  end

  def render_branch_list_items(branches)
    sorted_git_heads(branches).map do |branch|
      content_tag(:li, link_to(h(branch.name), log_path(branch.name),
                               :title => branch_link_title_text(branch)),
                  :class => "branch #{highlight_if_head(branch)}")
    end.join("\n  ")
  end

  def highlight_if_head(branch)
    if branch.head?
      "head"
    end
  end

  def branch_link_title_text(branch)
    h(branch.name) + (branch.head? ? " (HEAD)" : "")
  end

  # Sorts the +heads+ alphanumerically with the HEAD first
  def sorted_git_heads(heads)
    heads.select{|h| !h.head? }.sort{|a,b|
      a.name <=> b.name
    }.unshift(heads.find{|h| h.head? }).compact
  end

  # Renders a set of list items, cut off at around +max_line_length+
  def render_chunked_branch_list_items(repository, max_line_length = 80)
    heads = sorted_git_heads(repository.git.heads)

    cumulative_line_length = 0
    heads_to_display = heads.select do |h|
      cumulative_line_length += (h.name.length + 2)
      cumulative_line_length < max_line_length
    end

    list_items = heads_to_display.map do |head|
      li = %Q{<li class="#{highlight_if_head(head)}">}
      li << link_to(h(head.name), repo_owner_path(repository, :project_repository_commits_in_ref_path,
                 repository.project, repository, ensplat_path(head.name)),
              :title => branch_link_title_text(head))
      li << "</li>"
      li
    end

    if heads_to_display.size < repository.git.heads.size
      rest_size = repository.git.heads.size - heads_to_display.size
      list_items << %{<li class="rest-of-branches">
                        <small>and #{rest_size} more&hellip;</small>
                      </li>}
    end

    list_items.join("\n")
  end

  def show_clone_list_search?(group_clones, user_clones)
    user_clones.size >= 5 || group_clones.size >= 5
  end

  def class_name_for_clone_url_field(repository)
    active_types = []
    active_types << "git" if repository.git_cloning?
    active_types << "http" if repository.http_cloning?
    active_types << "ssh" if display_ssh_url?(repository)
    active_types.join("_")
  end

  def display_ssh_url?(repository)
    repository.display_ssh_url?(logged_in? ? current_user : nil)
  end

  def repo_clone_link(repository, owner, type)
    return "" if !repository.send("#{type}_cloning?")
    url = h(repository.send("#{type}_clone_url"))
    title = t("views.repos.show_page_title",
              :repo => repository.name, :title => h(owner.title))

    content_for(:extra_head) do
      "<link rel=\"vcs-#{type}\" href=\"#{url}\" title=\"#{title}\" />"
    end

    id = "#{type}-#{repository.id}"

    <<-HTML
      <p class="clone_radio">
        <label for="#{id}">
          <input type="radio" id="#{id}" name="url-#{repository.id}" value="#{url}" #{git_or_ssh_url_checked(repository, type)}>#{type.to_s.upcase}
        </label>
      </p>
    HTML
  end

  def git_or_ssh_url_checked(repo, type)
    checked = 'checked="checked"'
    return type == :ssh ? checked : "" if display_ssh_url?(repo)
    return type == :git ? checked : "" if repo.git_cloning?
    type == :http && repo.http_cloning? ? checked : ""
  end
end
