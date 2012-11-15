# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class GitHttpCloningTest < ActionController::IntegrationTest
  context "Request with git clone" do
    setup do
      @repository = repositories(:johans)
      @request_uri = "/johans-project/johansprojectrepos.git/HEAD"
    end

    should "set X-Sendfile headers" do
      assert_incremented_by(@repository.cloners, :count, 1) do
        get @request_uri, {}, :remote_addr => "192.71.1.2"
      end

      assert_response :success
      assert_not_nil(headers["X-Sendfile"])
      assert_equal(File.join(RepositoryRoot.default_base_path, @repository.real_gitdir, "HEAD"), headers["X-Sendfile"])
    end

    should "create cloner with correct remote address" do
      assert_incremented_by(@repository.cloners, :count, 1) do
        # This doesn't seem to work.
        # get @request_uri, {}, :remote_addr => "192.71.1.2"

        # This, however, is every bit as good
        Gitorious::GitHttpCloner.call({
          "PATH_INFO" => @request_uri,
          "REMOTE_ADDR" => "192.71.1.2"
        })

        last_cloner = @repository.cloners.last
        assert_equal("192.71.1.2", last_cloner.ip)
        assert_equal("http", last_cloner.protocol)
      end
    end

    should "set Robot Exclusion Protocol (REP) header" do
      get @request_uri

      assert_match /noindex/, headers["X-Robots-Tag"]
      assert_match /nofollow/, headers["X-Robots-Tag"]
    end

    should "use X-Accel-Redirect when running under nginx" do
      Gitorious.stubs(:frontend_server).returns("nginx")
      get @request_uri, {}, :host => "git.gitorious.local", :remote_addr => "192.71.1.2"

      assert_response :success
      assert_not_nil headers["X-Accel-Redirect"]
    end

    context "disabling of http cloning" do
      setup { GitoriousConfig["hide_http_clone_urls"] = true }
      teardown { GitoriousConfig["hide_http_clone_urls"] = false }

      should "not allow http cloning if denied by configuration" do
        get @request_uri, {}

        assert_response 403
        assert_nil headers['X-Sendfile']
      end
    end
  end
end
