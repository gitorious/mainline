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

class MergeRequestVersionsController < ApplicationController
  renders_in_site_specific_context

  def show
    @version = MergeRequestVersion.find(params[:id])
    @diffs = @version.diffs(extract_range_from_parameter(params[:commit_shas]))
    @repository = @version.merge_request.target_repository

    if params[:commit_shas] && !commit_range?(params[:commit_shas])
      @commit = @repository.git.commit(params[:commit_shas])
    end

    respond_to do |wants|
      wants.js { render :layout => false }
    end
  end

  private
  def commit_range?(shaish)
    shaish.include?("-")
  end

  def extract_range_from_parameter(param)
    @sha_range = if match = /^([a-z0-9]*)-([a-z0-9]*)$/.match(param)
      Range.new(match[1],match[2])
    else
      param
    end
  end
end
