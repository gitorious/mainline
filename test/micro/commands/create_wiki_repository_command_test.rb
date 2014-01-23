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
require "commands/create_wiki_repository_command"

class FakeApp < MessageHub
  def admin?(actor, subject); true; end
end

class CreateWikiRepositoryCommandTest < MiniTest::Spec
  before do
    @app = FakeApp.new
    @user = User.new
    @project = Project.new({
        :slug => "entombed",
        :user => @user,
        :owner => @user
      })
    @command = CreateWikiRepositoryCommand.new(@app)
  end

  describe "#build" do
    it "adds new repository to project" do
      repository = @command.build(@project)

      assert_equal "entombed-gitorious-wiki", repository.name
      assert_equal @user, repository.owner
      assert_equal @user, repository.user
      assert_nil repository.parent
      assert_equal :wiki, repository.kind
      refute repository.merge_requests_enabled
    end
  end

  describe "#execute" do
    it "creates repository" do
      count = Repository.count
      repository = @command.execute(@command.build(@project))

      assert_equal count + 1, Repository.count
    end

    it "creates committership for owner" do
      repository = @command.build(@project)
      repository.committerships.expects(:create_for_owner!)
      @command.execute(repository)
    end

    it "posts creation message" do
      repository = @command.build(@project)
      repository.id = 13
      repository = @command.execute(repository)

      assert_equal 1, @app.messages.length
      expected = {
        :queue => "/queue/GitoriousWikiRepositoryCreation",
        :message => {:id => 13 }
      }
      assert_equal(expected, @app.messages.first)
    end
  end
end
