# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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

class ParamsFinder
  def initialize(app, params, predefs = {})
    @app = app
    @params = params
    predefs.keys.each { |k| send(:"#{k}=", predefs[k]) if respond_to?(:"#{k}=", true) }
  end

  def project
    @project
  end

  def repository
    @repository
  end

  def merge_request
    @merge_request ||= auth(@repository.merge_requests.public.find_by_sequence_number!(params[:merge_request_id]))
  end

  def merge_request_version
    return @merge_request_version if @merge_request_version
    if params[:version].nil?
      @merge_request_version = auth(merge_request.versions.last)
    else
      @merge_request_version = auth(merge_request.versions.find_by_version!(params[:version]))
    end
    @merge_request_version
  end

  protected
  attr_reader :app, :params
  attr_writer :project, :repository

  def auth(thing)
    app.send(:authorize_access_to, thing)
  end
end
