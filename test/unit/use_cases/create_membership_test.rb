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
require "test_helper"
require "create_membership"

class App < MessageHub
  def admin?(actor, subject); true; end
end

class CreateMembershipTest < ActiveSupport::TestCase
  def setup
    @app = App.new
    @group = Group.first
    @user = @group.creator
  end

  def execute(params)
    CreateMembership.new(@app, @group, @user).execute(params)
  end

  should "create membership" do
    outcome = execute(:role => Role.member.id, :login => "moe")

    assert outcome.success?, outcome.to_s
    assert_equal Role.member, outcome.result.role
    assert_equal @group, outcome.result.group
    assert_equal users(:moe), outcome.result.user
  end

  should "message newly added member" do
    SendMessage.expects(:call).with(has_entries(sender: @user, recipient: users(:moe)))

    execute(:role => Role.member.id, :login => "moe")
  end

  should "not message added member if no sender" do
    count = Message.count
    outcome = CreateMembership.new(@app, @group).execute(:role => Role.member.id, :login => "moe")

    assert_equal count, Message.count
  end

  should "fail validation when missing login" do
    outcome = execute(:role => Role.member.id)

    refute outcome.success?
    refute_nil outcome.failure
  end

  should "create membership from user id and symbolic role" do
    outcome = execute(:role_name => Role::MEMBER, :user_id => users(:moe).id)

    assert outcome.success?, outcome.to_s
    assert_equal Role.member, outcome.result.role
    assert_equal @group, outcome.result.group
    assert_equal users(:moe), outcome.result.user
  end
end
