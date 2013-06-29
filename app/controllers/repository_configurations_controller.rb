# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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
require "gitorious/app"

class RepositoryConfigurationsController < ApplicationController
  always_skip_session

  # Used internally to check write permissions by gitorious
  def writable_by
    uc = RepositoryWritableBy.new(Gitorious::App, repository)
    outcome = uc.execute(:login => params[:username], :git_path => params[:git_path])
    pre_condition_failed(outcome)
    outcome.success { |result| render :text => result.to_s }
    outcome.failure { |err| render :text => "false" }
  end

  def show
    repo = authorize_configuration_access(repository)
    config_data = "real_path:#{repo.real_gitdir}\n"
    config_data << "force_pushing_denied:"
    config_data << (repo.deny_force_pushing? ? "true" : "false")
    headers["Cache-Control"] = "public, max-age=600"

    render :text => config_data, :content_type => "text/x-yaml"
  end

  private
  def repository
    project = Project.find_by_slug!(params[:project_id])
    project.cloneable_repositories.find_by_name!(params[:id])
  end

  def authorize_configuration_access(repository)
    return repository if !Gitorious.private_repositories?
    if !can_read?(User.find_by_login(params[:username]), repository)
      raise Gitorious::Authorization::UnauthorizedError.new(request.fullpath)
    end
    repository
  end
end
