# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "timeout"

class MergeRequestVersionsController < ApplicationController
  include Gitorious::View::DoltUrlHelper
  include ParamsModelResolver

  before_filter :find_project_and_repository
  renders_in_site_specific_context

  DiffNotAvailable = Class.new(StandardError)

  rescue_from DiffNotAvailable, :with => :rescue_from_diff_not_available

  def show
    raise DiffNotAvailable unless merge_request_version

    diffs = []
    timeout = false

    begin
      diffs = Timeout.timeout(Gitorious.diff_timeout) { merge_request_version.diffs }
    rescue Timeout::Error => err
      timeout = true
    end

    commit = merge_request.source_repository.git.commit(merge_request.ending_commit)

    if commit
      render(:show, :locals => {
          :project => @project,
          :repository => RepositoryPresenter.new(merge_request.target_repository),
          :merge_request => merge_request,
          :merge_request_version => merge_request_version,
          :renderer => diff_renderer(params[:diffmode], RepositoryPresenter.new(merge_request.source_repository), commit),
          :commit => commit,
          :diffs => diffs,
          :timeout => timeout,
          :user => merge_request.user,
          :source_repo => RepositoryPresenter.new(merge_request.source_repository),
          :target_repo => RepositoryPresenter.new(merge_request.target_repository),
          :range => commit_range(params[:commit_shas])
        })
    else
      raise DiffNotAvailable
    end
  end

  private

  def diff_renderer(mode, repository, commit)
    klass = mode == "sidebyside" ? Gitorious::Diff::SidebysideRenderer : Gitorious::Diff::InlineRenderer
    klass.new(self, repository, commit)
  end

  def commit_range(range)
    range || "#{merge_request_version.merge_base_sha}-#{merge_request.ending_commit}"
  end

  def rescue_from_diff_not_available
    flash[:warning] = 'Diff is no longer availabe for this Merge Request'

    redirect_back_or_default(
      project_repository_merge_request_path(
        merge_request.project, merge_request.target_repository, merge_request
      )
    ) and return
  end
end
