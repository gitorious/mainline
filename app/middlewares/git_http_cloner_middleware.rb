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

# Rack Middleware that handles HTTP cloning

require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
require(File.dirname(__FILE__) + "/../../app/racks/git_http_cloner")

class GitHttpClonerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    response = Gitorious::GitHttpCloner.call(env)
    return @app.call(env) if response[0] > 400 && response[0] < 500
    response
  end
end
