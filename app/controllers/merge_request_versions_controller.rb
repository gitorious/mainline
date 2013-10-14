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
  before_filter :find_project_and_repository
  renders_in_site_specific_context
  layout "ui3"

  def show
    diffs = []

    begin
      timeout = Timeout.timeout(Gitorious.diff_timeout) do
        diffs = merge_request_version.diffs(extract_range_from_parameter(params[:commit_shas]))
      end

      timeout = nil unless timeout.length == 0
    rescue Timeout::Error => err
      timeout = err
    end

    commit = merge_request.source_repository.git.commit(merge_request.ending_commit)

    render(:show, :locals => {
        :project => @project,
        :repository => RepositoryPresenter.new(merge_request.target_repository),
        :merge_request => merge_request,
        :merge_request_version => merge_request_version,
        :renderer => diff_renderer(params[:diffmode], RepositoryPresenter.new(merge_request.source_repository), commit),
        :commit => commit,
        :diffs => diffs,
        :timeout => timeout
      })
  end

  private
  def merge_request
    @merge_request ||= authorize_access_to(@repository.merge_requests.public.find_by_sequence_number!(params[:merge_request_id]))
  end

  def merge_request_version
    return @merge_request_version if @merge_request_version
    if params[:version].nil?
      @merge_request_version = authorize_access_to(merge_request.versions.last)
    else
      @merge_request_version = authorize_access_to(merge_request.versions.find_by_version!(params[:version]))
    end
    @merge_request_version
  end

  def diff_renderer(mode, repository, commit)
    klass = mode == "sidebyside" ? Gitorious::Diff::SidebysideRenderer : Gitorious::Diff::InlineRenderer
    klass.new(self, repository, commit)
  end

  def commit_range?(shaish)
    shaish.include?("-")
  end

  def extract_range_from_parameter(param)
    sha_range = if match = /^([a-z0-9]*)-([a-z0-9]*)$/.match(param)
      Range.new(match[1],match[2])
    else
      param
    end
  end
end
