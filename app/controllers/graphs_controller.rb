# encoding: utf-8
#--
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

class GraphsController < ApplicationController
  include CommitAction

  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  renders_in_site_specific_context

  def index
    commit_action do |head, ref, render_index|
      @commits = @repository.cached_paginated_commits(@ref, params[:page])
      render_index.call(:ref => @repository.head_candidate_name)
    end
  end

  private

  def ref_type
    :project_repository_graph_in_ref_path
  end
end
