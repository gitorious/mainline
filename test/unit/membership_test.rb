# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  should "have valid associations" do
    assert_equal groups(:team_thunderbird), memberships(:team_thunderbird_mike).group
    assert_equal roles(:admin), memberships(:team_thunderbird_mike).role
    assert_equal users(:mike), memberships(:team_thunderbird_mike).user
  end

  context "Adding members to a group" do
    setup do
      @group = FactoryGirl.create(:group)
      @user = @group.creator
      @inviter = FactoryGirl.create(:user)
    end

    should "nullify messages when deleted" do
      @invitee = FactoryGirl.create(:user)
      membership = Membership.create(:user => @invitee, :group => @group, :role => Role.member)
      Message.create!({
          :sender => @inviter,
          :recipient => membership.user,
          :subject => I18n.t("membership.notification_subject"),
          :body => I18n.t("membership.notification_body", {
              :inviter => @inviter.title,
              :group => membership.group.title,
              :role => membership.role.admin? ? "administrator" : "member"
            }),
          :notifiable => membership
        })
      message = membership.messages.first

      assert membership.destroy
      assert_nil message.reload.notifiable_type
      assert_nil message.notifiable_id
    end
  end

  context "A membership" do
    setup {
      @group = FactoryGirl.create(:group)
      @membership = FactoryGirl.create(:membership, :user => @group.creator, :group => @group)
    }

    should "be unique for each user" do
      duplicate_membership = Membership.new({
          :group => @membership.group,
          :user => @membership.user,
          :role => @membership.role
        })

      assert @membership.uniq?
      refute duplicate_membership.uniq?
    end
  end
end
