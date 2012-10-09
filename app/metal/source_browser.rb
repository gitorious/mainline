# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS and/or its subsidiary(-ies)
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

class SourceBrowser
  URL = /([^\/]+)\/([^\/]+)\/source\/(.+):(.*)/
  NOT_FOUND_RESPONSE = [404, {"Content-Type" => "text/html"},[]]

  def self.call(env)
    match, project_slug, repo, ref, path = *env["PATH_INFO"].match(URL)
    return NOT_FOUND_RESPONSE if !match
    project = Project.find_by_slug(project_slug)
    repository = project.repositories.find_by_name(repo)
    response = nil

    Gitorious::Dolt.new(project, repository).object(ref, path) do |err, data|
      if !err.nil?
        response = error(err, repo, ref)
      else
        response = success(Gitorious::Dolt.view.render(data[:type], data))
      end
    end

    response
  end

  def self.success(body)
    [200, { "Content-Type" => "text/html" }, [body]]
  end

  def self.error(err, repo, ref)
    [500, { "Content-Type" => "text/html" }, [err.message]]
  end
end
