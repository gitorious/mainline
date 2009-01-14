#--
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

class Action
  CREATE_PROJECT = 0
  DELETE_PROJECT = 1
  UPDATE_PROJECT = 2
  CLONE_REPOSITORY = 3
  DELETE_REPOSITORY = 4
  COMMIT = 5
  CREATE_BRANCH = 6
  DELETE_BRANCH = 7
  CREATE_TAG = 8
  DELETE_TAG = 9
  ADD_COMMITTER = 10
  REMOVE_COMMITTER = 11
  COMMENT = 12
  REQUEST_MERGE = 13
  RESOLVE_MERGE_REQUEST = 14
  UPDATE_MERGE_REQUEST = 15
  DELETE_MERGE_REQUEST = 16
  UPDATE_WIKI_PAGE = 17
  
  def self.name(action_id)
    case action_id
      when CREATE_PROJECT
        "create project"
      when DELETE_PROJECT
        "delete project"
      when UPDATE_PROJECT
        "update project"
      when CLONE_REPOSITORY
        "clone repository"
      when DELETE_REPOSITORY
        "delete repository"
      when COMMIT
        "commit"
      when CREATE_BRANCH
        "create branch"
      when DELETE_BRANCH
        "delete branch"
      when CREATE_TAG
        "create tag"
      when DELETE_TAG
        "delete tag"
      when ADD_COMMITTER
        "add committer"
      when REMOVE_COMMITTER
        "remove committer"
      when COMMENT
        "comment"
      when REQUEST_MERGE
        "request merge"
      when RESOLVE_MERGE_REQUEST
        "resolve merge request"
      when UPDATE_MERGE_REQUEST
        "update merge request"
      when DELETE_MERGE_REQUEST
        "delete merge request"
    end
  end
end
