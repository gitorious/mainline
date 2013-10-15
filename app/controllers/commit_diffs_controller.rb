# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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

class CommitDiffsController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits

  skip_session
  after_filter :cache_forever
  renders_in_site_specific_context

  def index
    return render_not_found unless find_commit
    @diffs = @commit.parents.empty? ? [] : @commit.diffs
    render :layout => !request.xhr?
  end

  def compare
    if params[:fragment]
      return render_not_found unless find_commit
      @first_commit_id = params[:from_id]
      @diffs = Grit::Commit.diff(@repository.git, @first_commit_id, params[:id])
      render :partial => "compare_diffs", :layout => false and return
    end
  end

  private
  def find_commit
    @comments = []
    @diffmode = params[:diffmode] == "sidebyside" ? "sidebyside" : "inline"
    @git = @repository.git

    @commit = @git.commit(params[:id])
    return unless @commit

    @root = Breadcrumb::Commit.new(:repository => @repository, :id => @commit.id_abbrev)
    @committer_user = User.find_by_email_with_aliases(@commit.committer.email)
    @author_user = User.find_by_email_with_aliases(@commit.author.email)
    @commit
  end
end
