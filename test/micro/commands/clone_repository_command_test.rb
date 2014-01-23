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
require "commands/clone_repository_command"

class FakeApp < MessageHub
  def admin?(actor, subject); true; end
end

class CloneRepositoryCommandTest < MiniTest::Spec
  before do
    @app = FakeApp.new
    @repo_owner = User.new(:id => 13)
    @user = User.new(:id => 42)
    @project = Project.new
    @repository = Repository.new({
        :name => "kickass-repo",
        :id => 42,
        :project => @project,
        :user => @repo_owner,
        :owner => @repo_owner
      })
    @command = CloneRepositoryCommand.new(@app, @repository, @user)

    def @user.groups
      groups = Object.new
      def groups.find(id)
        Group.new(:id => id)
      end
      groups
    end
  end

  describe "#build" do
    it "adds new user clone to project" do
      repository = @command.build(params(:name => "My clone"))

      assert_equal "My clone", repository.name
      assert_equal @user, repository.owner
      assert_equal @user, repository.user
      assert_equal @repository, repository.parent
      assert_equal :user, repository.kind
      assert repository.merge_requests_enabled
    end

    it "adds new group clone to project" do
      repository = @command.build(params(:owner_type => "Group", :owner_id => 3))

      assert_equal 3, repository.owner.id
      assert_instance_of Group, repository.owner
      assert_equal :team, repository.kind
    end

    it "suggests name from login" do
      repository = @command.build(params(:login => "cjohansen"))

      assert_equal "cjohansens-kickass-repo", repository.name
    end
  end

  describe "#execute" do
    it "creates repository" do
      count = Repository.count
      repository = @command.execute(@command.build(params))

      assert_equal count + 1, Repository.count
    end

    it "creates committership for owner" do
      repository = @command.build(params)
      repository.committerships.expects(:create_for_owner!)
      @command.execute(repository)
    end

    it "creates public clone by default" do
      Repository.stubs(:private_on_create?).returns(false)
      repository = @command.execute(@command.build(params))

      assert repository.public?
    end

    it "creates private clone if source repository is private" do
      @repository.make_private
      @repository.content_memberships = [OpenStruct.new(:member => { :id => 42 })]
      repository = @command.execute(@command.build(params))

      assert repository.private?
      assert_equal [{ :id => 42 }], repository.content_memberships
    end

    it "creates private clone" do
      Repository.stubs(:private_on_create?).returns(true)
      repository = @command.execute(@command.build(params))

      assert repository.private?
    end

    it "adds owner favorite" do
      repository = @command.build(params)
      repository.expects(:watched_by!).with(@user)
      @command.execute(repository)
    end

    it "creates event" do
      repository = @command.build(params)
      repository.parent_id = 42
      repository.created_at = Time.now
      @project.expects(:create_event).with(3, repository, @user, 42)
      @command.execute(repository)
    end

    it "posts creation message" do
      repository = @command.build(params)
      repository.id = 13
      repository = @command.execute(repository)

      assert_equal 1, @app.messages.length
      expected = {
        :queue => "/queue/GitoriousRepositoryCloning",
        :message => {:id => 13 }
      }
      assert_equal(expected, @app.messages.first)
    end
  end

  def params(hash = {})
    CloneRepositoryInput.new({
        :owner_type => "User"
      }.merge(hash))
  end
end
