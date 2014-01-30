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
require "test_helper"
require "add_committer"

class AddCommitterTest < ActiveSupport::TestCase
  setup do
    @repository = repositories(:johans)
    @user = users(:johan)
    @group = groups(:team_thunderbird)
  end

  should "add User as a committer" do
    moe = users(:moe)
    outcome = AddCommitter.new(@user, @repository).execute("user" => {"login" => moe.login},
                                                           "permissions" => ["review","commit"])
    assert outcome.success?
    assert_equal Committership.last, outcome.result
    assert_equal moe, outcome.result.committer
    assert_equal @user, outcome.result.creator
    assert_equal [:review, :commit], outcome.result.permission_list
  end

  should "add Group as a committer" do
    outcome = AddCommitter.new(@user, @repository).execute("group" => {"name" => @group.name},
                                                           "permissions" => ["review"])

    assert outcome.success?
    assert_equal Committership.last, outcome.result
    assert_equal @group, outcome.result.committer
    assert_equal @user, outcome.result.creator
    assert_equal [:review], outcome.result.permission_list
  end

  should "add Super Group as a committer" do
    Gitorious::Configuration.override("enable_super_group" => true) do
      outcome = AddCommitter.new(@user, @repository).execute("group" => {"name" => "Super Group"})

      assert outcome.success?
      assert_equal "super", outcome.result.id
      assert_equal [:review, :commit, :admin], outcome.result.permission_list
    end
  end

  should "not add invalid committer" do
    outcome = AddCommitter.new(@user, @repository).execute("group" => {"name" => "Super Group"})

    refute outcome.success?
  end
end
