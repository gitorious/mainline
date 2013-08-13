# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2010 Marius Mathiesen <marius@shortcut.no>
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

class ServiceProcessorTest < ActiveSupport::TestCase

  def setup
    @http_client = mock
    @processor = ServiceProcessor.new(@http_client)
    @repository = repositories(:johans)
    @repository.stubs(:full_repository_path).returns(push_test_repo_path)
    @processor.repository = @repository
    @user = users(:mike)

    @first_commit = "ec433174463a9d0dd32700ffa5bbb35cfe2a4530"
    @last_commit = "bb17eec3080ed71fa4ea7aba6b500aac9339e159"
    @spec = PushSpecParser.new(@first_commit, @last_commit, "refs/heads/master")
    grit = mock
    committer = Grit::Actor.new("John Committer", "noone@invalid.org")
    author = Grit::Actor.new("Jane Author", "jane@g.org")
    grit_commit = Grit::Commit.new(nil, SHA, [], nil,
      author, 1.day.ago,
      committer, 2.days.ago,
      ["Awesome sauce"])
    grit.stubs(:commits_between).with(@first_commit, @last_commit).returns([grit_commit])
    @repository.stubs(:git).returns(grit)

    @generator = Gitorious::ServicePayloadGenerator.new(@repository, @spec, @user)
    @payload = @generator.payload.with_indifferent_access
  end

  def add_hook_url(repository, url)
    create_web_hook(:repository => repository, :user => users(:johan), :url => url)
  end

  context "Extracting the message" do
    setup do
      @processor.expects(:notify_services).with(@payload, [])
      @processor.consume({
          :user => @user.login,
          :repository_id => @repository.id,
          :payload => @payload
        }.to_json)
    end

    should "extract the repository from the message" do
      assert_equal @repository, @processor.repository
    end

    should "extract the user from the message" do
      assert_equal @user, @processor.user
    end
  end

  def successful_response
    result = Net::HTTPSuccess.new("HTTP/1.1","200","OK")
    result.stubs(:body).returns("")
    result
  end

  def last_hook_response(repository)
    repository.services.first.reload.last_response
  end

  context "Notifying web hooks" do
    should "post the payload once for each hook" do
      add_hook_url(@repository, "http://foo.com/")
      add_hook_url(@repository, "http://bar.com/")
      Service.expects(:global_services).returns(build_web_hook(:url => "http://baz.com/"))
      @http_client.expects(:post).times(3).returns(successful_response)
      @processor.notify_services(@payload)
    end

    should "post the payload only to named web hook" do
      add_hook_url(@repository, "http://foo.com/")
      bar_hook = add_hook_url(@repository, "http://bar.com/")
      @http_client.expects(:post).times(1).returns(successful_response)

      @processor.consume({
          :user => @user.login,
          :repository_id => @repository.id,
          :payload => @payload,
          :service_id => bar_hook.id
        }.to_json)
    end

    should "update the hook with the response string" do
      @url = "http://example.com/hook"
      add_hook_url(@repository, @url)
      @http_client.expects(:post).returns(successful_response)
      @processor.notify_services(@payload)
      assert_equal "200 OK", last_hook_response(@repository)
    end
  end

  context "Error handling" do
    setup {
      add_hook_url(@repository, "http://access-denied.com/")
    }

    should "handle timeouts" do
      @http_client.expects(:post).raises(Timeout::Error, "Connection timed out")
      @processor.notify_services(@payload)
      assert_equal "Connection timed out", last_hook_response(@repository)
    end

    should "handle connection refused" do
      @http_client.expects(:post).raises(Errno::ECONNREFUSED, "Connection refused")
      @processor.notify_services(@payload)
      assert_equal "Connection refused", last_hook_response(@repository)
    end

    should "handle socket errors" do
      @http_client.expects(:post).raises(SocketError)
      @processor.notify_services(@payload)
      assert_equal "Socket error", last_hook_response(@repository)
    end

    should "log an error for an unknown repository" do
      assert_nothing_raised {
        @processor.logger.expects(:error)
        @processor.stubs(:notify_services)
        @processor.consume({:user => @user.login, :repository_id => "invalid repository name"}.to_json)
      }
    end

    should "log an error for an unknown user" do
      assert_nothing_raised {
        @processor.logger.expects(:error)
        @processor.stubs(:notify_services)
        @processor.consume({:user => "invalid login", :repository_id => @repository.id}.to_json)
      }
    end
  end

  context "HTTP responses" do
    should "consider any response in the 20x range successful" do
      response = Net::HTTPSuccess.new("HTTP/1.1","200","OK")
      assert @processor.successful_response?(response)
    end

    should "consider some redirects successful" do
      response = Net::HTTPFound.new("HTTP/1.1","302","Found")
      assert @processor.successful_response?(response)
    end

    should "consider all responses in the 40x range unsuccessful" do
      response = Net::HTTPNotFound.new("HTTP/1.1","404","Not found")
      assert !@processor.successful_response?(response)
    end
  end
end
