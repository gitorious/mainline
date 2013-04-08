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
require "virtus"

class CreateMembershipCommand
  def initialize(group, user = nil)
    @group = group
    @user = user
  end

  def execute(membership)
    membership.save!
    send_notification(membership) if membership.inviter
    membership
  end

  def build(params)
    Membership.new({
        :inviter => @user,
        :group => @group,
        :user => User.find_by_login(params.login),
        :role => Role.find(params.role)
      })
  end

  private
  def send_notification(membership)
    Message.create!({
        :sender => membership.inviter,
        :recipient => membership.user,
        :subject => I18n.t("membership.notification_subject"),
        :body => I18n.t("membership.notification_body", {
            :inviter => membership.inviter.title,
            :group => membership.group.title,
            :role => membership.role.admin? ? "administrator" : "member"
          }),
        :notifiable => membership
      })
  end
end

class NewMembershipParams
  include Virtus
  attribute :login, String
  attribute :role, Integer
end

class CreateMembership
  include UseCase

  def initialize(auth, group, user = nil)
    user = User.find(user) if user.is_a?(Integer)
    input_class(NewMembershipParams)
    add_pre_condition(AdminRequired.new(auth, group, user)) if user
    step(CreateMembershipCommand.new(group, user), :validator => MembershipValidator)
  end
end
