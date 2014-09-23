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

class RefPolicy

  Error = Class.new(StandardError)

  ERROR_MESSAGES = {
    create: "You are not allowed to create %{refname} in this repository",
    update: "You are not allowed to update %{refname} in this repository",
    force_update: "You are not allowed to force-update %{refname} in this repository",
    delete: "You are not allowed to delete %{refname} in this repository",
  }

  attr_reader :user, :ref

  def self.authorize_action!(user, repository, refname, oldsha, newsha, merge_base)
    ref = Ref.new(repository, refname)
    policy = new(user, ref)
    action = Ref.action(oldsha, newsha, merge_base)

    if !policy.public_send(:"#{action}?")
      error_message = ERROR_MESSAGES[action] % { refname: refname }
      raise Error, error_message
    end
  end

  def initialize(user, ref)
    @user = user
    @ref = ref
  end

  def create?
    return false unless user
    return false if ref.merge_request

    RepositoryPolicy.allowed?(user, ref.repository, :push)
  end

  def update?
    return false unless user

    if ref.merge_request && MergeRequestPolicy.allowed?(user, ref.merge_request, :update)
      return true
    end

    RepositoryPolicy.allowed?(user, ref.repository, :push)
  end

  def force_update?
    return false unless user
    return false unless ref.force_update_allowed?

    if ref.merge_request && MergeRequestPolicy.allowed?(user, ref.merge_request, :update)
      return true
    end

    RepositoryPolicy.allowed?(user, ref.repository, :push)
  end

  def delete?
    return false unless user
    return false unless ref.force_update_allowed?
    return false if ref.merge_request

    RepositoryPolicy.allowed?(user, ref.repository, :push)
  end

end
