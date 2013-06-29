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
require "use_case"

class RepositoryWritableBy
  include UseCase

  def initialize(app, repository)
    add_pre_condition(RequiredDependency.new(:repository, repository))
    step(RepositoryWritableByCommand.new(app, repository))
  end
end

class RepositoryWritableByCommand
  def initialize(app, repository)
    @app = app
    @repository = repository
  end

  def execute(params)
    user = User.find_by_login(params[:login])
    return false if !user

    begin
      if merge_request = get_merge_request(params[:git_path])
        return true if merge_request.user == user
      elsif @app.can_push?(user, @repository)
        return true
      end
    rescue ActiveRecord::RecordNotFound
      false
    end

    return false
  end

  private
  def get_merge_request(path)
    result = /^refs\/merge-requests\/(\d+)$/.match(path.to_s)
    return nil if !result
    seqnum = result[1]
    @repository.merge_requests.find_by_sequence_number!(seqnum)
  end
end
