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

class MergeRequestCommentsJSONPresenter

  attr_reader :app, :comments

  def initialize(app, comments)
    @app = app
    @comments = comments
  end

  def render_for(user)
    JSON.dump(hash_for(user))
  end

  def hash_for(user)
    comments.map { |c| comment_hash(c, user) }
  end

  protected

  def comment_hash(comment, user)
    CommitCommentJSONPresenter.new(app, comment).hash_for(user)
  end

end
