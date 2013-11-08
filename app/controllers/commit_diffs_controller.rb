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
require "gitorious/diff/inline_renderer"
require "gitorious/diff/sidebyside_renderer"
require "gitorious/view/dolt_url_helper"

class CommitDiffsController < ApplicationController
  include Gitorious::View::DoltUrlHelper
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  before_filter :load_commit
  skip_session
  after_filter :cache_forever
  renders_in_site_specific_context

  attr_reader :commit

  def show
    repository = RepositoryPresenter.new(@repository)
    range      = CommitRangePresenter.build(params[:from_id], params[:id], @repository)

    render("show", :locals => {
        :renderer => diff_renderer(params[:diffmode], repository, commit),
        :range => range,
        :repository => repository,
        :commit => commit,
        :diffs => Grit::Commit.diff(@repository.git, params[:from_id], params[:id])
      })
  end

  private

  def diff_renderer(mode, repository, commit)
    klass = mode == "sidebyside" ? Gitorious::Diff::SidebysideRenderer : Gitorious::Diff::InlineRenderer
    klass.new(self, repository, commit)
  end

  def load_commit
    @commit = @repository.git.commit(params[:id])
    render_not_found and return false unless @commit
  end
end
