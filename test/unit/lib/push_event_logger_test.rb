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
  NULL_SHA = "0" * 32
  SHA = "a" * 32
  OTHER_SHA = "f" * 32
  
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
      @project = Project.new
      @repository = Repository.new(:project => @project)
      @user = User.new
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

    should_eventually "provide a usable body" do
      event = @logger.build_meta_event

      assert_equal("New branch", event.body)
    end
  end
end
