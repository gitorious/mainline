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
require "test_helper"

class WikiUpdateEventLoggerTest < ActiveSupport::TestCase

  context "updating wiki" do
    setup do
      @repository = repositories(:johans_wiki)
      @user = @repository.user
      @commit = Gitorious::Wiki::Commit.new
      Gitorious::Wiki::CommitParser.any_instance.expects(:fetch_from_git).returns([@commit])
      @spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/master")
    end
    
    should "create update wiki page event for updated pages" do
      @commit.modified_file_names = %w[Home.mdown]
      logger = Gitorious::Wiki::UpdateEventLogger.new(@repository, @spec, @user)

      assert_incremented_by @repository.project.events, :size, 1 do
        logger.create_wiki_events
      end

      event = @repository.project.events.last
      assert_equal @user, event.user
    end

    should "create update wiki page event for added pages" do
      @commit.added_file_names = %w[Home.mdown]
      logger = Gitorious::Wiki::UpdateEventLogger.new(@repository, @spec, @user)

      assert_incremented_by @repository.project.events, :size, 1 do
        logger.create_wiki_events
      end

      event = @repository.project.events.last
      assert_equal @user, event.user
    end
  end
end
