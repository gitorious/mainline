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

class PushProcessorTest < ActiveSupport::TestCase
  def setup
    @processor = PushProcessor.new
  end

  #should_subscribe_to :push
  should_consume "/queue/GitoriousPush"

  context "Parsing" do
    setup do
      @repository = repositories(:johans)
      @user = @repository.user
      json = {
        :gitdir => @repository.hashed_path,
        :username => @user.login,
        :message => "#{NULL_SHA} #{SHA} refs/heads/master"
      }.to_json
      @processor.consume(json)
    end

    should "recognize the user who pushed" do
      assert_equal @user, @processor.user
    end

    should "recognize the repository pushed to" do
      assert_equal @repository, @processor.repository
    end

    should "recognize the push spec" do
      assert_equal NULL_SHA, @processor.spec.from_sha.sha
      assert_equal SHA, @processor.spec.to_sha.sha
      assert_equal "master", @processor.spec.ref_name
    end
  end

  context "ActiveRecord connections" do
    setup do
      @repository = repositories(:johans)
      @user = @repository.user
      @processor.stubs(:process_push)
      @json = {
        :gitdir => @repository.hashed_path,
        :username => @user.login,
        :message => "#{NULL_SHA} #{SHA} refs/heads/master"
      }.to_json
    end
    
    should "be re-established" do
      @processor.expects(:verify_connections!)
      @processor.consume(@json)
    end
  end

  context "Merge request update" do
    setup do
      @repository = repositories(:johans)
      @user = @repository.user
      @merge_request = merge_requests(:moes_to_johans)
      @payload = {
        "gitdir" => @repository.hashed_path,
        "username" => @user.login,
        "message" => "#{SHA} #{OTHER_SHA} refs/merge-requests/#{@merge_request.sequence_number}"
      }
    end

    should "be processed as such" do
      @processor.expects(:process_merge_request)
      @processor.expects(:process_push).never
      @processor.expects(:process_wiki_update).never
      @processor.consume(@payload.to_json)
    end

    should "update merge request" do
      @processor.stubs(:merge_request).returns(@merge_request)
      @merge_request.expects(:update_from_push!)
      @processor.load_message(@payload)
      @processor.process_merge_request
    end

    should "not fail if username is nil" do
      @payload[:username] = nil
      @processor.stubs(:merge_request).returns(@merge_request)
      @merge_request.expects(:update_from_push!)
      @processor.consume(@payload.to_json)
    end

    should "not process if action is delete" do
      @payload["message"] = "#{SHA} #{NULL_SHA} refs/merge-requests/19"
      @processor.stubs(:merge_request).returns(@merge_request)

      assert_nothing_raised do
        @processor.consume(@payload.to_json)
      end
    end

    should_eventually "locate the correct merge request" do
      # @repository.merge_requests.expect(:find_by_sequence_number!).with(@merge_request.sequence_number)
    end
  end

  context "Regular push" do
    setup do
      @repository = repositories(:johans)
      @user = @repository.user
      @payload = {
        "gitdir" => @repository.hashed_path,
        "username" => @user.login,
        "message" => "#{SHA} #{OTHER_SHA} refs/heads/master"
      }
      PushEventLogger.any_instance.stubs(:calculate_commit_count).returns(2)
    end

    should "be processed as such" do
      @processor.expects(:process_push)
      @processor.expects(:process_merge_request).never
      @processor.expects(:process_wiki_update).never
      @processor.consume(@payload.to_json)
    end

    should "log push event" do
      PushEventLogger.any_instance.stubs(:create_push_event?).returns(true)
      PushEventLogger.any_instance.expects(:create_push_event)
      @processor.load_message(@payload)
      @processor.process_push
    end

    should "log meta event" do
      PushEventLogger.any_instance.stubs(:create_meta_event?).returns(true)
      PushEventLogger.any_instance.expects(:create_meta_event)
      @processor.load_message(@payload)
      @processor.process_push
    end

    should "register push on repository" do
      @processor.stubs(:repository).returns(@repository)
      @repository.expects(:register_push)
      @processor.load_message(@payload)
      @processor.process_push
    end

    should "fail if username is nil" do
      @payload["username"] = nil
      @processor.stubs(:repository).returns(@repository)
      @repository.expects(:register_push).never
      @processor.load_message(@payload)

      assert_raise RuntimeError do
        @processor.process_push
      end
    end
  end

  context "Wiki update" do
    setup do
      @repository = repositories(:johans_wiki)
      @user = @repository.user
      @payload = {
        "gitdir" => @repository.hashed_path,
        "username" => @user.login,
        "message" => "#{SHA} #{OTHER_SHA} refs/heads/master"
      }
    end

    should "be processed as such" do
      @processor.expects(:process_wiki_update)
      @processor.expects(:process_push).never
      @processor.expects(:process_merge_request).never
      @processor.consume(@payload.to_json)
    end

    should "log wiki events" do
      Gitorious::Wiki::UpdateEventLogger.any_instance.expects(:create_wiki_events).returns(true)
      @processor.load_message(@payload)
      @processor.process_wiki_update
    end

    should "fail if username is nil" do
      @payload["username"] = nil
      Gitorious::Wiki::UpdateEventLogger.any_instance.expects(:create_wiki_events).returns(true).never
      @processor.load_message(@payload)

      assert_raise RuntimeError do
        @processor.process_wiki_update
      end
    end
  end

  context "Triggering the web hooks" do
    setup do
      @repository = repositories(:johans)
      @user = @repository.user

      message = {
        "gitdir" => @repository.hashed_path,
        "username" => @user.login,
        "message" => "#{SHA} #{OTHER_SHA} refs/heads/master"
      }

      @processor.load_message(message)
      PushEventLogger.any_instance.stubs(:calculate_commit_count).returns(2)
    end

    should "not trigger web hooks unless repository has some" do
      @processor.expects(:trigger_hooks).never
      @processor.process_push
    end

    should "trigger web hooks if repository has hooks" do
      @repository.hooks.create!(:user => users(:moe), :url => "http://g.org/hooks")
      @processor.expects(:trigger_hooks)
      @processor.process_push
    end

    should "create a generator and generate for repos with hooks" do
      @repository.hooks.create!(:user => users(:moe), :url => "http://g.org/hooks")
      Gitorious::WebHookGenerator.any_instance.expects(:generate!).once
      @processor.trigger_hooks
    end
  end
end
