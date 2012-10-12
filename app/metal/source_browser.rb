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
  ROUTE = /([^\/]+)\/([^\/]+)\/(source|blame|history|raw|tree_history|refs|readme)(?:\/([^:]+)(?::(.*))?)?/
  NOT_FOUND = [404, {}, []]

  def initialize(project, repository)
    @project = project
    @repository = repository
    @dolt = Gitorious::Dolt.new(project, repository)
  end

  def self.call(env)
    match, proj, repo, action, ref, path = *env["PATH_INFO"].match(ROUTE)
    return NOT_FOUND if match.nil?
    return redirect("/#{proj}/#{repo}/#{action}/master:#{path}") if ref.nil?
    project = Project.find_by_slug(proj)
    repository = project && project.repositories.find_by_name(repo)
    action = action && action.to_sym
    source_browser = new(project, repository)
    return NOT_FOUND if project.nil? || repository.nil? || !source_browser.respond_to?(action)
    response = nil
    Gitorious::Dolt.in_reactor do
      source_browser.send(action, ref, path) { |r| response = r }
    end

    response || NOT_FOUND
  end

  def source(ref, path, &block)
    @dolt.tree_entry(ref, path) do |err, data|
      next block.call(error(err, ref, path)) if !err.nil?
      block.call(success(@dolt.render(data[:type], data)))
    end
  end

  def readme(ref, path, &block)
    # Redirect to detected readme file
    block.call([200, {}, ["TODO"]])
  end

  def blame(ref, path, &block)
    @dolt.blame(ref, path) do |err, data|
      next block.call(error(err, ref, path)) if !err.nil?
      block.call(success(@dolt.render(:blame, data)))
    end
  end

  def history(ref, path, &block)
    @dolt.history(ref, path, 20) do |err, data|
      next block.call(error(err, ref, path)) if !err.nil?
      block.call(success(@dolt.render(:commits, data)))
    end
  end

  def raw(ref, path, &block)
    #action(:raw, dolt, repository, ref, path, &block)
    [200, {}, ["TODO"]]
  end

  def tree_history(ref, path, &block)
    #action(:tree_history, dolt, repository, ref, path, &block)
    [200, {}, ["TODO"]]
  end

  def refs(ref, path, &block)
    #action(:refs, dolt, repository, ref, path, &block)
    [200, {}, ["TODO"]]
  end

  def success(body)
    [200, { "Content-Type" => "text/html" }, [body]]
  end

  def error(err, ref, path)
    [500, { "Content-Type" => "text/html" }, [err.respond_to?(:message) ? err.message : err]]
  end

  def self.redirect(url)
    [301, { "Location" => url }, []]
  end

  private
  def results(err, template, data, ref, path)
    if !err.nil?
      block.call(error(err, ref, path))
    else
      block.call(success(@dolt.render(template, data)))
    end
  end
end
