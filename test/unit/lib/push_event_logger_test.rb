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

class PushEventLoggerTest < ActiveSupport::TestCase
  
  context "deciding what events to create" do
    context "for tags" do
      should "create meta event when creating" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_meta_event?
      end

      should "not create push event when creating" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_push_event?
      end

      should "not create meta event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_meta_event?
      end

      should "not create push event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_push_event?
      end

      should "create meta event when deleting" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_meta_event?
      end

      should "not create push event when deleting" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/1.0")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_push_event?
      end
    end

    context "for heads" do
      should "create meta event when creating" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_meta_event?
      end

      should "not create push event when creating" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_push_event?
      end

      should "not create meta event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_meta_event?
      end

      should "create push event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_push_event?
      end

      should "create meta event when deleting" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert logger.create_meta_event?
      end

      should "not create push event when deleting" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_push_event?
      end
    end

    context "for merge requests" do
      should "not create meta event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/merge-requests/134")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_meta_event?, "Merge request meta events should be created in the model"
      end
    end

    should "not create a push event when updating" do
        spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/merge-requests/134")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        assert !logger.create_push_event?      
    end
  end

  context "deciding the action for the meta event" do
    context "for tags" do
      should "be Action::CREATE_TAG when creating a tag" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/tags/feature")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        event = logger.build_meta_event
        assert_equal Action::CREATE_TAG, event.action
      end

      should "be Action::DELETE_TAG when deleting a tag" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/feature")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        event = logger.build_meta_event
        assert_equal Action::DELETE_TAG, event.action
      end
    end

    context "for heads" do
      should "be Action::CREATE_BRANCH when creating a head" do
        spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        event = logger.build_meta_event
        assert_equal Action::CREATE_BRANCH, event.action
      end

      should "be Action::DELETE_BRANCH when deleting a head" do
        spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/master")
        logger = PushEventLogger.new(Repository.new, spec, User.new)

        event = logger.build_meta_event
        assert_equal Action::DELETE_BRANCH, event.action
      end
    end
  end

  context "meta events" do
    setup do
      @repository = repositories(:johans)
      @project = @repository.project
      @user = @repository.user
      @create_spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/master")
      @logger = PushEventLogger.new(@repository, @create_spec, @user)
    end

    should "be new records" do
      event = @logger.build_meta_event

      assert event.new_record?
    end

    should "belong to repository's project" do
      event = @logger.build_meta_event

      assert_equal @project, event.project
    end

    should "belong to the user pushing" do
      event = @logger.build_meta_event

      assert_equal @user, event.user
    end

    should "target repository" do
      event = @logger.build_meta_event

      assert_equal @repository, event.target
    end

    should "identify name of the head that changed" do
      event = @logger.build_meta_event

      assert_equal @create_spec.ref_name, event.data
    end

    should "build and save meta event" do
      event = @logger.create_meta_event

      assert !event.new_record?
    end
  end

  context "Meta event message" do
    should "describe new branches" do
      new_branch_spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
      logger = PushEventLogger.new(Repository.new, new_branch_spec, User.new)
      event = logger.build_meta_event

      assert_equal("Created branch master", event.body)
    end

    should "describe new tags" do
      new_tag_spec = PushSpecParser.new(NULL_SHA, SHA, "refs/tags/release")
      logger = PushEventLogger.new(Repository.new, new_tag_spec, User.new)
      event = logger.build_meta_event


      assert_equal "Created tag release", event.body
    end

    should "describe deleted tags" do
      deleted_tag_spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/release")
      logger = PushEventLogger.new(Repository.new, deleted_tag_spec, User.new)
      event = logger.build_meta_event


      assert_equal "Deleted tag release", event.body      
    end

    should "describe deleted branches" do
      deleted_branch_spec = PushSpecParser.new(SHA, NULL_SHA, "refs/heads/topic")
      logger = PushEventLogger.new(Repository.new, deleted_branch_spec, User.new)
      event = logger.build_meta_event

      assert_equal "Deleted branch topic", event.body
    end
  end

  context "Push event" do
    setup do
      @repository = repositories(:johans)
      @user = users(:johan)
      @spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/heads/master")
      @logger = PushEventLogger.new(@repository, @spec, @user)
      @event = @logger.build_push_event
    end
    
    should "have a user" do
      assert_equal @user, @event.user
    end

    should "have a project" do
      assert_equal @repository.project, @event.project
    end

    should "have a target" do
      assert_equal @repository, @event.target
    end

    should "have an action" do
      assert_equal Action::PUSH_SUMMARY, @event.action
    end

    should "know how many commits were pushed" do
      git = mock
      log =<<GIT_LOG
58226ba392520deb36cf89a7c1e85c047e9d1b2b Make sure meta events create usable meta and data attributes
c8db6a4907fc3cd7762e862ea2e1f1683ba00e5f Merge request update events are created from the model
bea57a4ac3a6590d1c66f3fadd986943d9830dde Start building event objects in PushEventLogger
04a7d04b72c5e9da75b775f0ff0b9b424465313a Start implementation of push event logger/factory
e0a6a4f6604efa4a6ab9f83e9bbc92c3a27bd625 Add documentation
GIT_LOG
      git.expects(:log).with({:pretty => "oneline"}, [SHA,OTHER_SHA].join("..")).returns(log)
      grit = mock(:git => git)
      @repository.expects(:git).returns(grit)

      assert_equal(5, @logger.calculate_commit_count)
    end

    should "create a push event with the appropriate data" do
      @logger.expects(:calculate_commit_count).returns(10)
      event = @logger.create_push_event
            
      assert_equal([SHA, OTHER_SHA, "master", "10"].join(PushEventLogger::PUSH_EVENT_DATA_SEPARATOR), event.data)
    end
  end

  context "Parsing the event body" do
    setup do
      body = [SHA, OTHER_SHA, "master", "10"].join(PushEventLogger::PUSH_EVENT_DATA_SEPARATOR)
      @result = PushEventLogger.parse_event_data(body)
    end
    
    should "contain the start sha" do
      assert_equal SHA, @result[:start_sha]
    end

    should "contain the end sha" do
      assert_equal OTHER_SHA, @result[:end_sha]
    end

    should "contain the branch name" do
      assert_equal "master", @result[:branch]
    end

    should "contain the commit count" do
      assert_equal "10", @result[:commit_count]
    end

    should "contain a shortened start sha" do
      assert_equal SHA[0,7], @result[:start_sha_short]
    end

    should "contain a shortened end sha" do
      assert_equal OTHER_SHA[0,7], @result[:end_sha_short]
    end
  end
end
