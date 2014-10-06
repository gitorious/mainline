# encoding: utf-8
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

class UpdateMergeRequestTargetRepository

  attr_reader :git_repository_pusher

  def self.call(merge_request)
    new(Gitorious::Git::Repository).call(merge_request)
  end

  def initialize(git_repository_pusher)
    @git_repository_pusher = git_repository_pusher
  end

  def call(merge_request)
    git_repository_pusher.push(
      merge_request.source_repository_path,
      merge_request.target_repository_path,
      refspec(merge_request)
    )
  end

  private

  def refspec(merge_request)
    "+#{merge_request.ending_commit}:#{merge_request.ref_name}"
  end

end
