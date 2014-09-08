#--
#   Copyright (C) 2014 Gitorious AS
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

class GitHttpController < ApplicationController

  def authorize
    repository = get_repository
    user = get_user

    headers['Content-Type'] = 'text/plain'

    if RepositoryPolicy.allowed?(user, repository, command)
      repository.cloned_from(request.remote_ip, nil, nil, "http")
      headers['X-Accel-Redirect'] = x_accel_redirect_path(repository.real_gitdir)
      render nothing: true
    else
      if user
        render text: "Permission denied", status: 403
      else
        request_http_basic_authentication("Gitorious")

        if request.authorization.blank?
          self.response_body = "Anonymous access denied"
        else
          self.response_body = "Invalid username or password"
        end
      end
    end
  end

  private

  def get_repository
    path = "#{params[:project_slug]}/#{params[:repository_name]}"
    Repository.find_by_path(path) or raise ActiveRecord::RecordNotFound
  end

  def get_user
    authenticate_with_http_basic do |username, password|
      User.authenticate(username, password)
    end
  end

  def command
    regexp = /git[\s-](upload-pack|receive-pack)/
    params[:service].to_s[regexp, 1] || params[:slug].to_s[regexp, 1] || 'upload-pack'
  end

  def x_accel_redirect_path(real_gitdir)
    if request.query_string.present?
      query_string = "?#{request.query_string}"
    end

    "/_internal/git/#{real_gitdir}#{params[:slug]}#{query_string}"
  end

end
