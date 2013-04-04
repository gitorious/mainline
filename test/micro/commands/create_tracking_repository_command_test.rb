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
require "fast_test_helper"
require "commands/create_tracking_repository_command"
require "ostruct"

class App < MessageHub
  def admin?(actor, subject); true; end
end

class CreateTrackingRepositoryCommandTest < MiniTest::Shoulda
  def setup
    @app = App.new
    @user = User.new
    @project = Project.new
    @repository = Repository.new({
        :id => 42,
        :project => @project,
        :user => @user,
        :owner => @user
      })
    @command = CreateTrackingRepositoryCommand.new(@app, @repository)
  end

  context "#build" do
    should "add new repository to project" do
      repository = @command.build

      assert_equal "tracking_repository_for_42", repository.name
      assert_equal @user, repository.owner
      assert_equal @user, repository.user
      assert_equal @repository, repository.parent
      assert_equal :tracking, repository.kind
    end
  end

  context "#execute" do
    should "create repository" do
      count = Repository.count
      repository = @command.execute(@command.build)

      assert_equal count + 1, Repository.count
      assert_equal "tracking_repository_for_42", repository.name
      assert_equal @user, repository.owner
      assert_equal @user, repository.user
      assert_equal :tracking, repository.kind
      refute repository.merge_requests_enabled
    end

    should "create committership for owner" do
      repository = @command.build
      repository.committerships.expects(:create_for_owner!).with(@user)
      @command.execute(repository)
    end

    should "create public project by default" do
      Repository.stubs(:private_on_create?).returns(false)
      repository = @command.execute(@command.build)

      assert repository.public?
    end

    should "create private project if parent is private" do
      @repository.make_private
      @repository.content_memberships = [OpenStruct.new(:member => { :id => 42 })]
      repository = @command.execute(@command.build)

      assert repository.private?
      assert_equal [{ :id => 42 }], repository.content_memberships
    end

    should "post creation message" do
      repository = @command.build
      repository.id = 13
      repository = @command.execute(repository)

      assert_equal 1, @app.messages.length
      expected = {
        :queue => "/queue/GitoriousTrackingRepositoryCreation",
        :message => {:id => 13 }
      }
      assert_equal(expected, @app.messages.first)
    end
  end
end
