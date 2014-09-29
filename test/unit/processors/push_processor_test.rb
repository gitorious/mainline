# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
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

class PushProcessorTest < ActiveSupport::TestCase
  def setup
    @processor = PushProcessor.new
    @start_sha = "ec433174463a9d0dd32700ffa5bbb35cfe2a4530"
    @end_sha = "7b5fe553c3c37ffc8b4b7f8c27272a28a39b640f"
  end

  should_consume "/queue/GitoriousPush"

  context "Parsing" do
    setup do
      @repository = repositories(:johans)
      path = (Rails.root + "test/fixtures/push_test_repo").to_s
      @repository.update_attribute(:hashed_path, path)
      @user = @repository.user
      json = {
        :repository_id => @repository.id,
        :username => @user.login,
        :message => "#{NULL_SHA} #{@end_sha} refs/heads/master"
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
      assert_equal @end_sha, @processor.spec.to_sha.sha
      assert_equal "master", @processor.spec.ref_name
    end
  end

  context "ActiveRecord connections" do
    setup do
      @repository = repositories(:johans)
      @user = @repository.user
      @processor.stubs(:process_push)
      @json = {
        :repository_id => @repository.id,
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
        "repository_id" => @repository.id,
        "username" => @user.login,
        "message" => "#{SHA} #{OTHER_SHA} refs/merge-requests/#{@merge_request.sequence_number}"
      }
      CreateNewMergeRequestVersion.stubs(:call).with(@merge_request)
    end

    should "be processed as such" do
      @processor.expects(:process_merge_request)
      @processor.expects(:process_push).never
      @processor.expects(:process_wiki_update).never
      @processor.consume(@payload.to_json)
    end

    should "update merge request tracking repository" do
      @processor.stubs(:merge_request).returns(@merge_request)
      CreateNewMergeRequestVersion.expects(:call).with(@merge_request)
      @processor.load_message(@payload)
      @processor.process_merge_request
    end

    should "not fail if username is nil" do
      @payload[:username] = nil
      @processor.stubs(:merge_request).returns(@merge_request)
      @processor.consume(@payload.to_json)
    end

    should "not process if action is delete" do
      @payload["message"] = "#{SHA} #{NULL_SHA} refs/merge-requests/19"
      @processor.stubs(:merge_request).returns(@merge_request)

      assert_nothing_raised do
        @processor.consume(@payload.to_json)
      end
    end

    should "not process if action is create" do
      @payload["message"] = "#{NULL_SHA} #{SHA} refs/merge-requests/19"
      @processor.stubs(:merge_request).returns(@merge_request)

      @processor.consume(@payload.to_json)
    end
  end

  context "Regular push" do
    setup do
      @repository = repositories(:johans)
      Repository.any_instance.stubs(:full_repository_path).returns(push_test_repo_path)
      @user = @repository.user
      @payload = {
        "repository_id" => @repository.id,
        "username" => @user.login,
        "message" => "#{NULL_SHA} #{@end_sha} refs/heads/master"
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

    should "mirror the repository changes" do
      Gitorious.mirrors.expects(:push).with(@repository)
      @processor.load_message(@payload)
      @processor.process_push
    end
  end

  context "Wiki update" do
    setup do
      @repository = repositories(:johans_wiki)
      @user = @repository.user
      @payload = {
        "repository_id" => @repository.id,
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

  context "Triggering the service notifications" do
    setup do
      @repository = repositories(:johans)
      Repository.any_instance.stubs(:full_repository_path).returns(push_test_repo_path)
      @user = @repository.user

      message = {
        "repository_id" => @repository.id,
        "username" => @user.login,
        "message" => "#{NULL_SHA} #{@end_sha} refs/heads/master"
      }

      @processor.load_message(message)
      PushEventLogger.any_instance.stubs(:calculate_commit_count).returns(2)
    end

    should "not trigger service notifications unless repository has some" do
      @processor.expects(:trigger_services).never
      @processor.process_push
    end

    should "trigger service notifications if repository has services" do
      create_web_hook(:repository => @repository, :user => users(:moe), :url => "http://g.org/hooks")
      @processor.expects(:trigger_services)
      @processor.process_push
    end

    should "create a generator and generate for repos with services" do
      create_web_hook(:repository => @repository, :user => users(:moe), :url => "http://g.org/hooks")
      Gitorious::ServicePayloadGenerator.any_instance.expects(:generate!).once
      @processor.trigger_services
    end
  end
end
