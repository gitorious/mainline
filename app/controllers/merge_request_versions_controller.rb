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
    @commits = @version.commits(extract_range_from_parameter(params[:commit_shas]))
    @repository = @version.merge_request.target_repository

    respond_to {|wants|
      wants.js {render :layout => false}
    }
  end
  
  private
  def extract_range_from_parameter(p)
    if match = /([a-z0-9]*)\.\.([a-z0-9]*)/.match(p)
      Range.new(match[1],match[2])
    else
      p
    end
  end
end
