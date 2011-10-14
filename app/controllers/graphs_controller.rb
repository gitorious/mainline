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
  REF_TYPE = :project_repository_graph_in_ref_path
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  renders_in_site_specific_context

  def index
    if params[:branch].blank?
      redirect_to_ref(@repository.head_candidate.name, REF_TYPE) and return
    end

    @git = @repository.git
    @ref, @path = branch_and_path(params[:branch], @git)

    head = get_head(@ref)
    return handle_unknown_ref(@ref, @git, REF_TYPE) if head.nil?

    if stale_conditional?(head.commit.id, head.commit.committed_date.utc)
      @root = Breadcrumb::Branch.new(head, @repository)
      @commits = @repository.cached_paginated_commits(@ref, params[:page])
      @atom_auto_discovery_url = project_repository_formatted_commits_feed_path(@project, @repository, params[:branch], :atom)
      respond_to do |format|
        format.html
      end
    end
  end
end
