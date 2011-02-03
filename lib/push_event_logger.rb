# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

class PushEventLogger
  def initialize(repository, spec, user)
    @repository = repository
    @spec = spec
    @user = user
  end

  def create_meta_event?
    !@spec.action_update? || @spec.merge_request?
  end

  def create_push_event?
    @spec.action_update? && @spec.head?
  end

  def build_meta_event
    Event.new(:action => meta_event_type, :project => @repository.project,
              :user => @user, :target => @repository, :data => @spec.ref_name)
  end

  private
  def meta_event_type
    return head_meta_event_type if @spec.head?
    return tag_meta_event_type if @spec.tag?
    merge_request_meta_event_type
  end

  def head_meta_event_type
    @spec.action_create? ? Action::CREATE_BRANCH : Action::DELETE_BRANCH
  end

  def tag_meta_event_type
    @spec.action_create? ? Action::CREATE_TAG : Action::DELETE_TAG
  end

  def merge_request_meta_event_type
    Action::UPDATE_MERGE_REQUEST
  end
end
