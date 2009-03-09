# encoding: utf-8
#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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


require File.dirname(__FILE__) + '/../test_helper'

class MembershipTest < ActiveSupport::TestCase
  should "has valid associations" do
    assert_equal groups(:team_thunderbird), memberships(:team_thunderbird_mike).group
    assert_equal roles(:admin), memberships(:team_thunderbird_mike).role
    assert_equal users(:mike), memberships(:team_thunderbird_mike).user
  end
  
  context 'Adding members to a group' do
    setup do
      @group = groups(:team_thunderbird)
      @user = users(:mike)
      @inviter = users(:johan)
    end
    
    should 'send a message to a newly added member after he is added to the group' do
      membership = Membership.build_invitation(@inviter, :user => @user, :group => @group, :role => roles(:member))
      assert membership.save
      message = @user.received_messages.last
      assert_equal(@inviter, message.sender)
      assert_equal(membership, message.notifiable)
    end
    
    should 'not send a notification if no inviter is set' do
      membership = Membership.new(:user => @user, :group => @group, :role => roles(:member))
      membership.expects(:send_notification).never
      membership.save
    end
  end
end
