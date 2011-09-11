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

require "capillary/log_parser"
require "capillary/commit"
require "gitorious/git_shell"

module Api
  class GraphsController < ApplicationController
    skip_session

    rescue_from Gitorious::GitShell::GitTimeout, :with => :render_timeout

    LOG_FORMAT = '%H§%P§%ai§%ae§%d§%s§'

    def show
      project = Project.find_by_slug(params[:project_id])
      repository = project.repositories.find_by_name(params[:repository_id])
      type = params[:type] == "all" ? "--all" : ""

      ref = "#{project.slug}/#{repository.name}/#{params[:branch]}"
      data = Rails.cache.fetch("commit-graph-#{ref}#{type}", :expires_in => 1.hour) do
        graph_log(repository, type, params[:branch])
      end

      parser = Capillary::LogParser.new
      data.split("\n").each { |line| parser << line }

      respond_to do |wants|
        wants.json { render :json => parser.to_json }
      end
    end

    private
    def graph_log(repo, type, branch = nil)
      args = [repo.full_repository_path, "--decorate=full", "-100", type]
      args << desplat_path(branch) if branch
      git_shell.send(:graph_log, *args)
    end

    def git_shell
      Gitorious::GitShell.new
    end

    def render_timeout
      render :json => []
    end
  end
end
