# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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

class WebHookGeneratorTest < ActiveSupport::TestCase

  def setup
    @repository = repositories(:johans)

    grit = mock
    grit.stubs(:commits_between).with(SHA, OTHER_SHA).returns([grit_commit])
    @repository.stubs(:git).returns(grit)

    @spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/master")
    @user = @repository.user

    @generator = Gitorious::WebHookGenerator.new(@repository, @spec, @user)
  end

  context "Publishing messages" do
    should "publish a message once only" do
      @generator.stubs(:payload).returns({})
      moe = users(:moe)
      hook = @repository.hooks.create!(
        :user => moe,
        :url  => "http://sandbox.org/web-hooks")
      second_hook = @repository.hooks.create!(
        :user => moe,
        :url  => "http://sandbox.org/ciabot.rb")

      @generator.generate!

      assert_messages_published "/queue/GitoriousPostReceiveWebHook", 1
      assert_published("/queue/GitoriousPostReceiveWebHook", {
                         "user" => @user.login,
                         "repository_id" => @repository.id,
                         "payload" => {}
                       })
    end

    should "be a message sender" do
      assert @generator.respond_to?(:publish)
    end
  end

  def grit_commit
    committer = Grit::Actor.new("John Committer", "noone@invalid.org")
    author = Grit::Actor.new("Jane Author", "jane@g.org")
    grit_commit = Grit::Commit.new(nil, SHA, [], nil,
      author, 1.day.ago,
      committer, 2.days.ago,
      ["Awesome sauce"])
  end
end
