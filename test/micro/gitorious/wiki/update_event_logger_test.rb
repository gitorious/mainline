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
require "fast_test_helper"
require "push_spec_parser"
require "gitorious/wiki/commit"
require "gitorious/wiki/commit_parser"
require "gitorious/wiki/update_event_logger"

class WikiUpdateEventLoggerTest < MiniTest::Spec
  describe "updating wiki" do
    before do
      @repository = Repository.new
      @repository.project = Project.new
      @user = User.new
      @commit = Gitorious::Wiki::Commit.new
      Gitorious::Wiki::CommitParser.any_instance.expects(:fetch_from_git).returns([@commit])
      @spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/master")
    end

    it "creates update wiki page event for updated pages" do
      @commit.modified_file_names = %w[Home.mdown]
      logger = Gitorious::Wiki::UpdateEventLogger.new(@repository, @spec, @user)

      logger.create_wiki_events

      assert_equal 1, @repository.project.events.length
      assert_equal @user, @repository.project.events.first[:user]
    end

    it "creates update wiki page event for added pages" do
      @commit.added_file_names = %w[Home.mdown]
      logger = Gitorious::Wiki::UpdateEventLogger.new(@repository, @spec, @user)

      logger.create_wiki_events

      assert_equal 1, @repository.project.events.length
      assert_equal @user, @repository.project.events.first[:user]
    end
  end
end
