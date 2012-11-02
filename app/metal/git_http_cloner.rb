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

# Middleware that handles HTTP cloning

require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
require(File.dirname(__FILE__) + "/../../lib/gitorious/git_http_cloner")

class GitHttpCloner
  def initialize(app)
    @app = app
  end

  def call(env)
    perform_http_cloning = env["HTTP_HOST"] =~ /^#{Site::HTTP_CLONING_SUBDOMAIN}\..*/

    if !perform_http_cloning || GitoriousConfig["hide_http_clone_urls"]
      return @app.call(env)
    end

    if env["PATH_INFO"] =~ /^\/robots.txt$/
      body = ["User-Agent: *\nDisallow: /\n"]
      return [200, { "Content-Type" => "text/plain" }, body]
    end

    if !/(.*\.git)(.*)/.match(env["PATH_INFO"])
      return @app.call(env)
    end

    Gitorious::GitHttpCloner.call(env)
  end
end
