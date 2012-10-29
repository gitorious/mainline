# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

  context 'Adding members to a group' do
    setup do
      @group = FactoryGirl.create(:group)
      @user = @group.creator
      @inviter = FactoryGirl.create(:user)
    end

    should 'send a message to a newly added member after he is added to the group' do
      @user.received_messages.destroy_all
      membership = Membership.build_invitation(@inviter, :user => @user, :group => @group, :role => Role.member)
      assert membership.save
      assert_not_nil message = @user.received_messages.find(:first, :conditions => {:notifiable_id => membership.id, :notifiable_type => membership.class.name})
      assert_equal(@inviter, message.sender)
      assert_equal(membership, message.notifiable)
    end

    should 'nullify messages when deleted' do
      @invitee = FactoryGirl.create(:user)
      @user.received_messages.destroy_all
      membership = Membership.build_invitation(@inviter, :user => @invitee, :group => @group, :role => Role.member)
      membership.save
      message = membership.messages.first
      assert membership.destroy
      assert_nil message.reload.notifiable_type
      assert_nil message.notifiable_id
    end

    should 'not send a notification if no inviter is set' do
      membership = Membership.new(:user => @user, :group => @group, :role => roles(:member))
      membership.expects(:send_notification).never
      membership.save
    end
  end

  context 'The group creator' do
    setup do
      @group = FactoryGirl.create(:group)
      @creator = @group.creator
      @membership = FactoryGirl.create(:membership, :user => @creator, :group => @group)
      assert_equal @creator, @group.creator
    end

    should 'not be demotable' do
      @membership.role = Role.member
      assert !@membership.save
      assert !@membership.valid?
    end

    should 'not be deletable' do
      assert !@membership.destroy
    end
  end

  context 'A membership' do
    setup {
      @group = FactoryGirl.create(:group)
      @membership = FactoryGirl.create(:membership, :user => @group.creator, :group => @group)
    }

    should 'be unique for each user' do
      duplicate_membership = Membership.new(:group => @membership.group, :user => @membership.user, :role => @membership.role)
      assert !duplicate_membership.save
    end
  end
end
