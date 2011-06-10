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
require File.dirname(__FILE__) + '/../../test_helper'

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

  context "Generating payload" do
    should "contain the start sha" do
      payload = @generator.payload
      assert_equal SHA, payload[:before] 
    end

    should "contain the end sha" do
      payload = @generator.payload
      assert_equal OTHER_SHA, payload[:after] 
    end

    should "contain the username of the pusher" do
      payload = @generator.payload
      assert_equal @user.login, payload[:pushed_by]
    end

    should "contain the ref pushed to" do
      payload = @generator.payload
      assert_equal "master", payload[:ref]
    end

    should "contain the pushed_at in XML schema" do
      payload = @generator.payload
      assert_equal @repository.last_pushed_at.xmlschema, payload[:pushed_at]
    end

    should "contain project name and description" do
      project = @repository.project      
      project.update_attribute(:slug, "my-project")
      project.update_attribute(:description, "Yes, mine")
      payload = @generator.payload

      assert_equal "my-project", payload[:project][:name]
      assert_equal "Yes, mine", payload[:project][:description]
    end

    should "contain repository information" do
      @repository.name = "name"
      @repository.description = "Terrible hacks"
      payload = @generator.payload
      
      assert_equal "#{GitoriousConfig['scheme']}://#{GitoriousConfig['gitorious_host']}/#{@repository.project.slug}/#{@repository.name}", payload[:repository][:url]
      assert_equal "name", payload[:repository][:name]
      assert_equal "Terrible hacks", payload[:repository][:description]
      assert_equal 1, payload[:repository][:clones]

      assert_equal({ :name => "johan" }, payload[:repository][:owner])
    end
  end

  context "commits" do
    should "get commits between start and end sha" do
      grit = mock
      grit.expects(:commits_between).with(SHA, OTHER_SHA).returns([])
      @repository.stubs(:git).returns(grit)
      @generator.fetch_commits
    end

    should "return list of commit details" do
      commits = @generator.fetch_commits

      assert_equal 1, commits.count
      commit = commits.first

      assert_equal "jane@g.org", commit[:author][:email]
      assert_equal "Jane Author", commit[:author][:name]
      assert_equal 2.days.ago.xmlschema, commit[:committed_at]
      assert_equal SHA, commit[:id]
      assert_equal "Awesome sauce", commit[:message]
      assert_equal 1.day.ago.xmlschema, commit[:timestamp]
      assert_equal "#{@repository.browse_url}/commit/#{SHA}", commit[:url]
    end

    should "contain a list of commits" do
      payload = @generator.payload
      
      assert_kind_of Array, payload[:commits]
    end
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
