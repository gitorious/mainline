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
require "commands/create_project_repository_command"

class App < MessageHub
  def admin?(actor, subject); true; end
end

class CreateProjectRepositoryCommandTest < MiniTest::Shoulda
  def setup
    @app = App.new
    @user = User.new
    @project = Project.new(:owner => @user)
    @command = CreateProjectRepositoryCommand.new(@app, @project, @user)
  end

  context "#build" do
    should "add new repository to project" do
      input = params
      repository = @command.build(input)

      assert_equal input.name, repository.name
      assert_equal input.description, repository.description
      assert_equal @project.repositories.first, repository
      assert_equal @user, repository.owner
      assert_equal @user, repository.user
    end
  end

  context "#execute" do
    should "create repository" do
      count = Repository.count
      repository = execute(params)

      assert_equal count + 1, Repository.count
      assert_equal "my_repo", repository.name
      assert_equal @project.owner, repository.owner
      assert_equal @user, repository.user
      assert_equal :project, repository.kind
    end

    should "create repository owned by group" do
      group = {}
      @project.owner = group
      repository = execute(params)

      assert_equal group, repository.owner
    end

    should "enable merge requests by default" do
      repository = execute(params)

      assert repository.merge_requests_enabled
    end

    should "opt-out of merge requests" do
      repository = execute(params("merge_requests_enabled" => "0"))

      refute repository.merge_requests_enabled
    end

    should "create committership for owner" do
      repository = @command.build(params)
      repository.committerships.expects(:create_for_owner!).with(@user)
      @command.execute(repository)
    end

    should "create public repository by default" do
      Repository.stubs(:private_on_create?).returns(false)
      repository = execute(params)

      assert repository.public?
    end

    should "create private project" do
      Repository.stubs(:private_on_create?).with(:private => true).returns(true)
      repository = execute(params(:private => "1"))

      assert repository.private?
    end

    should "create public project" do
      Repository.stubs(:private_on_create?).with(:private => false).returns(false)
      repository = execute(params(:private => "0"))

      assert repository.public?
    end

    should "add owner favorite" do
      repository = @command.build(params)
      repository.expects(:watched_by!).with(@user)
      @command.execute(repository)
    end

    should "create event" do
      repository = @command.build(params)
      @project.expects(:create_new_repository_event).with(repository)
      @command.execute(repository)
    end

    should "post creation message" do
      repository = @command.build(params)
      repository.id = 13
      repository = @command.execute(repository)

      assert_equal 1, @app.messages.length
      expected = {
        :queue => "/queue/GitoriousRepositoryCreation",
        :message => { :id => 13 }
      }
      assert_equal(expected, @app.messages.first)
    end
  end

  def execute(command, input = nil)
    if input.nil?
      input = command
      command = @command
    end
    command.execute(command.build(params(input)))
  end

  def params(hash = {})
    NewRepositoryInput.new({
        "name" => "my_repo",
        "description" => "A fine repository"
      }.merge(hash))
  end
end
