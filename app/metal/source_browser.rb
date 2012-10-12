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
    env["rack.session.options"] = {}
    ActiveRecord::Base.establish_connection
    match, proj, repo, action, ref, path = *env["PATH_INFO"].match(ROUTE)
    return NOT_FOUND if match.nil?

    project = Project.find_by_slug(proj)
    repository = project && project.repositories.find_by_name(repo)
    source_browser = new(project, repository)
    action = action && action.to_sym
    return NOT_FOUND if project.nil? || repository.nil? || !source_browser.respond_to?(action)

    source_browser.dispatch(action, ref, path)
  end

  def dispatch(action, ref, path)
    if action != :refs && ref.nil? #|| ref.length != 40
      #ref = @dolt.rev_parse_oid_sync(ref || "HEAD")
      ref = "master"
      return redirect("/#{@project.slug}/#{@repository.name}/#{action}/#{ref}:#{path}")
    end

    Gitorious::Dolt.in_reactor do |done|
      send(action, ref, path) { |r| done.call(r) }
    end
  end

  def source(ref, path, &block)
    @dolt.tree_entry(ref, path) do |err, data|
      next block.call(error(err, ref, path)) if !err.nil?
      block.call(success(@dolt.render(data[:type], data)))
    end
  end

  # def readme(ref, path, &block)
  #   # Redirect to detected readme file
  #   block.call([200, {}, ["TODO"]])
  # end

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
    @dolt.blob(ref, path) do |err, data|
      next block.call(error(err, ref, path)) if !err.nil?
      body = @dolt.render(:raw, data, :layout => nil)
      block.call(success(body, "text/plain"))
    end
  end

  def tree_history(ref, path, &block)
    @dolt.tree_history(ref, path, 1) do |err, data|
      next block.call(error(err, ref, path)) if !err.nil?
      body = @dolt.render(:tree_history, data, :layout => nil)
      block.call(success(body, "application/json"))
    end
  end

  def refs(ref, path, &block)
    @dolt.refs do |err, data|
      next block.call(error(err, ref, path)) if !err.nil?
      body = @dolt.render(:refs, data, :layout => nil)
      block.call(success(body, "application/json"))
    end
  end

  def success(body, content_type = "text/html")
    [200, { "Content-Type" => content_type }, [body]]
  end

  def error(err, ref, path)
    [500, { "Content-Type" => "text/html" }, [err.respond_to?(:message) ? err.message : err]]
  end

  def redirect(url)
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
