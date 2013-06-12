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
class DoltAuthMiddleware
  def initialize(app)
    @app = app
  end

  # TODO:
  # - We may have private repositories but still public mode
  # - Decorate Cache-Control headers if public
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

    if private_mode
      return access_denied("Login required") unless user
      if Gitorious::App.can_read?(repository, user)
        return result
      else
        return access_denied "You don't have access to this repository"
      end
    else
      if Gitorious::App.can_read?(repository, user)
        return result
      else
        return access_denied "You don't have access to this repository"
      end
    end
  end

  def log(message)
    Rails.logger.info ">> Session: #{message}"
  end

  private
  def access_denied(reason)
    [403, {"Content-Type" => "text/html"}, [reason]]
  end
end
