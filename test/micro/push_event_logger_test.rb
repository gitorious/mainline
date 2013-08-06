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
require "app/models/action"
require "push_spec_parser"
require "push_event_logger"
require "push_commit_extractor"

class PushEventLoggerTest < MiniTest::Spec
  describe "deciding what events to create" do
    describe "for tags" do
      it "creates meta event when creating" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_meta_event?
      end

      it "creates a push event when creating" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        refute logger.create_push_event?
      end

      it "does not create meta event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_meta_event?
      end

      it "does not create push event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        refute logger.create_push_event?
      end

      it "creates meta event when deleting" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_meta_event?
      end

      it "does not create push event when deleting" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_push_event?
      end
    end

    describe "for heads" do
      it "creates meta event when creating" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_meta_event?
      end

      it "does not create push event when creating" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_push_event?
      end

      it "does not create meta event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_meta_event?
      end

      it "creates push event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_push_event?
      end

      it "creates meta event when deleting" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_meta_event?
      end

      it "does not create push event when deleting" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_push_event?
      end
    end

    describe "for merge requests" do
      it "does not create meta event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/merge-requests/134")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_meta_event?, "Merge request meta events should be created in the model"
      end
    end

    it "does not create a push event when updating" do
      spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/merge-requests/134")
      logger = PushEventLogger.new(Repository.new, spec, User.new)

      assert !logger.create_push_event?
    end
  end

  describe "deciding the action for the meta event" do
    describe "for tags" do
      it "is Action::CREATE_TAG when creating a tag" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/tags/feature")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        event = logger.build_meta_event
        assert_equal Action::CREATE_TAG, event.action
      end

      it "is Action::DELETE_TAG when deleting a tag" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/feature")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        event = logger.build_meta_event
        assert_equal Action::DELETE_TAG, event.action
      end
    end

    describe "for heads" do
      it "is Action::CREATE_BRANCH when creating a head" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        event = logger.build_meta_event
        assert_equal Action::CREATE_BRANCH, event.action
      end

      it "is Action::DELETE_BRANCH when deleting a head" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        event = logger.build_meta_event
        assert_equal Action::DELETE_BRANCH, event.action
      end
    end
  end

  describe "meta events" do
    before do
      @repository = Repository.new #repositories(:johans)
      @project = @repository.project
      @user = @repository.user
      @create_spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/master")
      @logger = PushEventLogger.new(@repository, @create_spec, @user)
    end

    it "is new records" do
      event = @logger.build_meta_event

      assert event.new_record?
    end

    it "belongs to repository's project" do
      event = @logger.build_meta_event

      assert_equal @project, event.project
    end

    it "belongs to the user pushing" do
      event = @logger.build_meta_event

      assert_equal @user, event.user
    end

    it "targets repository" do
      event = @logger.build_meta_event

      assert_equal @repository, event.target
    end

    it "identifies name of the head that changed" do
      event = @logger.build_meta_event

      assert_equal @create_spec.ref_name, event.data
    end

    it "builds and saves meta event" do
      event = @logger.create_meta_event

      assert !event.new_record?
    end
  end

  describe "Meta event message" do
    it "describes new branches" do
      new_branch_spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
      logger = PushEventLogger.new(Repository.new, new_branch_spec, User.new)
      event = logger.build_meta_event

      assert_equal("Created branch master", event.body)
    end

    it "describes new tags" do
      new_tag_spec = PushSpecParser.new(NULL_SHA, SHA, "refs/tags/release")
      logger = PushEventLogger.new(Repository.new, new_tag_spec, User.new)
      event = logger.build_meta_event


      assert_equal "Created tag release", event.body
    end

    it "describes deleted tags" do
      deleted_tag_spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/release")
      logger = PushEventLogger.new(Repository.new, deleted_tag_spec, User.new)
      event = logger.build_meta_event


      assert_equal "Deleted tag release", event.body
    end

    it "describes deleted branches" do
      deleted_branch_spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/topic")
      logger = PushEventLogger.new(Repository.new, deleted_branch_spec, User.new)
      event = logger.build_meta_event

      assert_equal "Deleted branch topic", event.body
    end
  end

  describe "Push event" do
    before do
      @repository = Repository.new #repositories(:johans)
      @repository.full_repository_path = (Rails.root + "test/fixtures/push_test_repo.git").to_s
      @user = User.new #users(:johan)
      @spec = PushSpecParser.new("ec433174463a9d0dd32700ffa5bbb35cfe2a4530", "bb17eec3080ed71fa4ea7aba6b500aac9339e159", "refs/heads/master")
      @logger = PushEventLogger.new(@repository, @spec, @user)
      @event = @logger.build_push_event
    end

    it "has a user" do
      assert_equal @user, @event.user
    end

    it "has a project" do
      assert_equal @repository.project, @event.project
    end

    it "has a target" do
      assert_equal @repository, @event.target
    end

    it "has an action" do
      assert_equal Action::PUSH_SUMMARY, @event.action
    end

    it "knows how many commits were pushed" do
      assert_equal(1, @logger.calculate_commit_count)
    end

    it "creates a push event with the appropriate data" do
      event = @logger.create_push_event

      assert_equal([@spec.from_sha.sha, @spec.to_sha.sha, "master", "1"].join(PushEventLogger::PUSH_EVENT_DATA_SEPARATOR), event.data)
    end
  end

  describe "Parsing the event body" do
    before do
      body = [SHA, OTHER_SHA, "master", "10"].join(PushEventLogger::PUSH_EVENT_DATA_SEPARATOR)
      @result = PushEventLogger.parse_event_data(body)
    end

    it "contains the start sha" do
      assert_equal SHA, @result[:start_sha]
    end

    it "contains the end sha" do
      assert_equal OTHER_SHA, @result[:end_sha]
    end

    it "contains the branch name" do
      assert_equal "master", @result[:branch]
    end

    it "contains the commit count" do
      assert_equal "10", @result[:commit_count]
    end

    it "contains a shortened start sha" do
      assert_equal SHA[0,7], @result[:start_sha_short]
    end

    it "contains a shortened end sha" do
      assert_equal OTHER_SHA[0,7], @result[:end_sha_short]
    end
  end
end
