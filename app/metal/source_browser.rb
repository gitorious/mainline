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
  ROUTE = /([^\/]+)\/([^\/]+)\/(source|blame|history|raw|tree_history|refs)(?:\/([^:]+)(?::(.*))?)?/
  NOT_FOUND = [404, {}, []]

  def self.call(env)
    match, proj, repo, action, ref, path = *env["PATH_INFO"].match(ROUTE)
    action = action && action.to_sym
    return NOT_FOUND if match.nil? || !respond_to?(action)
    return redirect("/#{proj}/#{repo}/#{action}/master:#{path}") if ref.nil?
    project = Project.find_by_slug(proj)
    repository = project && project.repositories.find_by_name(repo)
    return NOT_FOUND if project.nil? || repository.nil?
    response = nil
    dolt = Gitorious::Dolt.new(project, repository)
    send(action, dolt, project, repository, ref, path) { |r| response = r }
    response
  end

  def self.source(dolt, project, repository, ref, path, &block)
    dolt.object(ref, path) do |err, data|
      if !err.nil?
        block.call(error(err, repository, ref))
      else
        block.call(success(dolt.render(data[:type], data)))
      end
    end
  end

  def self.blame(dolt, project, repository, ref, path, &block)
    block.call([200, {}, ["TODO"]])
  end

  def self.history(dolt, project, repository, ref, path, &block)
    block.call([200, {}, ["TODO"]])
  end

  def self.raw(dolt, project, repository, ref, path, &block)
    block.call([200, {}, ["TODO"]])
  end

  def self.tree_history(dolt, project, repository, ref, path, &block)
    block.call([200, {}, ["TODO"]])
  end

  def self.refs(dolt, project, repository, ref, path, &block)
    block.call([200, {}, ["TODO"]])
  end

  def self.success(body)
    [200, { "Content-Type" => "text/html" }, [body]]
  end

  def self.error(err, repository, ref)
    [500, { "Content-Type" => "text/html" }, [err.message]]
  end

  def self.redirect(url)
    [301, { "Location" => url }, []]
  end
end
