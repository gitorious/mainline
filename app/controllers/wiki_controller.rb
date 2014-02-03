# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class WikiController < ApplicationController
  protected
  def render_index(owner, wiki, atom_path)
    respond_to do |format|
      format.html do
        render("pages/index", :locals => {
            :owner => owner,
            :tree_nodes => tree_nodes(wiki),
            :atom_auto_discovery_url => atom_path
          })
      end

      format.atom do
        expires_in(30.minutes)
        render("pages/index", :locals => {
            :commits => wiki.commits("master", 30),
            :owner => owner
          })
      end
    end
  end

  def render_show(owner, page)
    if page.binary?
      return render :text => page.content
    end

    if page.new?
      return render_not_found unless default_format?
      redirect_to(edit_wiki_page_path(owner, params[:id])) and return if logged_in?
      render("pages/no_page", :locals => { :owner => owner, :page => page }) and return
    end

    render("pages/show", :locals => {
        :atom_auto_discovery_url => wiki_index_path(owner, :format => :atom),
        :page => page,
        :owner => owner
      })
  end

  def render_page_history(owner, wiki, page)
    redirect_to(edit_wiki_page_path(owner, page)) if page.new? and return
    commits = page.history(30)

    render("pages/history", :locals => {
        :page => page,
        :owner => owner,
        :wiki_repository => wiki,
        :commits => commits,
        :user_and_email_map => Repository.users_by_commits(commits)
      })
  end

  def render_git_access(owner, wiki)
    render("pages/git_access", :locals => {
        :owner => owner,
        :wiki_repository => wiki
      })
  end

  def render_edit(owner, page)
    page.user = current_user
    render("pages/edit", :locals => { :page => page, :owner => owner })
  end

  def tree_nodes(wiki)
    wiki.tree.contents.select do |n|
      n.name =~ /\.#{Page::DEFAULT_FORMAT}$/
    end
  end

  def default_format?
    params[:format].blank?
  end

  helper_method :page_history_path
  helper_method :wiki_index_path
  helper_method :wiki_index_url
  helper_method :wiki_page_path
  helper_method :wiki_git_access_path
  helper_method :edit_wiki_page_path
  helper_method :show_writable_wiki_url?
end
