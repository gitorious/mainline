# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class DoltAuthMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    result = @app.call(env)
    if !env["dolt"]
      log "Not inside Dolt"
      return result
    end
    repo = env["dolt"][:repository]
    request = Rack::Request.new(env)
    user_id = request.session["user_id"]
    user = user_id ? User.find(user_id) : nil
    repository = Repository.find_by_path(repo)
    private_mode = !Gitorious.public?
    return access_denied("Login required") if private_mode && !user
    return result if Gitorious::App.can_read?(user, repository)
    access_denied("You don't have access to this resource")
  end

  def log(message)
    Rails.logger.info ">> Session: #{message}"
  end

  private
  def access_denied(reason)
    content = self.class.tpl.sub("<!-- <%= reasons %> -->", "<p>#{reason}</p>")
    [403, {"Content-Type" => "text/html"}, [content]]
  end

  def self.tpl
    @template ||= File.read(Rails.root + "public/403.html")
  end
end
