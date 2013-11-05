# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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
require "gitorious/view/dolt_url_helper"

class CommitsController < ApplicationController
  include Gitorious::View::DoltUrlHelper
  include CommitAction

  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  renders_in_site_specific_context

  def index
    commit_action do |ref, head, render_index|
      page = JustPaginate.page_value(params[:page])
      total_pages = @repository.git_derived_total_commit_count(ref) / 30
      @commits = @repository.paginated_commits(ref, page, 30)

      render_index.call(
        :ref => head.commit.id,
        :commits => @commits,
        :page => page,
        :total_pages => total_pages)
    end
  end

  def show
    repository = RepositoryPresenter.new(@repository)
    presenter = CommitPresenter.new(@repository, params[:id])
    handle_missing_sha and return if !presenter.exists?

    respond_to do |format|
      format.html do
        render("show", :locals => {
            :commit => presenter,
            :mode => params[:diffmode] == "sidebyside" ? :sidebyside : :inline,
            :renderer => diff_renderer(params[:diffmode], repository, presenter.commit)
          })
      end

      format.diff do
        render({ :text => presenter.raw_diffs, :content_type => "text/plain" })
      end

      format.patch do
        render(:text => presenter.to_patch, :content_type => "text/plain")
      end
    end
  end

  def feed
    number_of_commits = 50
    initial_number_of_commmits = 1

    expires_in(30.minutes, :public => true)
    @git = @repository.git
    @ref = desplat_path(params[:id])
    @commits = @repository.git.commits(@ref, initial_number_of_commmits)
    return if @commits.empty?
    if stale?(:etag => @commits.first.id, :last_modified => @commits.first.committed_date.utc)
      @commits += @repository.git.commits(@ref, number_of_commits - initial_number_of_commmits, initial_number_of_commmits)
      respond_to do |format|
        format.atom
      end
    end
  end

  private

  def diff_renderer(mode, repository, commit)
    klass = mode == "sidebyside" ? Gitorious::Diff::SidebysideRenderer : Gitorious::Diff::InlineRenderer
    klass.new(self, repository, commit)
  end

  def ref_type
    :project_repository_commits_in_ref_path
  end
end
