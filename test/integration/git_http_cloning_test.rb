# encoding: utf-8
#--
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
require File.join(File.dirname(__FILE__), "..", "test_helper")

class GitHttpCloningTest < ActionController::IntegrationTest
  context 'Request with git clone' do
    setup do
      @repository = repositories(:johans)
      @request_uri = '/johans-project/johansprojectrepos.git/HEAD'
    end

    should 'set X-Sendfile headers for subdomains allowing HTTP cloning' do
      ['git.gitorious.org','git.gitorious.local','git.foo.com'].each do |host|
        assert_incremented_by(@repository.cloners, :count, 1) do
          get @request_uri, {}, :host => host, :remote_addr => '192.71.1.2'
          last_cloner = @repository.cloners.last
          assert_equal('192.71.1.2', last_cloner.ip)
          assert_equal('http', last_cloner.protocol)
        end
        assert_response :success
        assert_not_nil(headers['X-Sendfile'])
        assert_equal(File.join(GitoriousConfig['repository_base_path'], @repository.real_gitdir, "HEAD"), headers['X-Sendfile'])
      end
    end

    context "disabling of http cloning" do
      setup { GitoriousConfig['hide_http_clone_urls'] = true }
      teardown { GitoriousConfig['hide_http_clone_urls'] = false }

      should "not allow http cloning if denied by configuration" do
        ['git.gitorious.org','git.gitorious.local','git.foo.com'].each do |host|
          get @request_uri, {}, :host => host
          assert_response :not_found
          assert_nil headers['X-Sendfile']
        end
      end
    end
    
    should 'not set X-Sendfile for hosts that do not allow HTTP cloning' do
      ['gitorious.local','foo.local'].each do |host|
        get @request_uri, {}, :host => host
        assert_response :not_found
        assert_nil(headers['X-Sendfile'])
      end
    end
  end

  context "robots.txt generation" do
    should "generate a robots.txt entry disallowing indexing" do
      get "/robots.txt", {}, :host => "git.gitorious.local"
      assert_response :success
      assert_equal "text/plain", headers["Content-Type"]
      assert_equal "User-Agent: *\nDisallow: /\n", @response.body
    end

    should "not generate a robots.txt entry for non git subdomain" do
      get "/robots.txt", {}, :host => "gitorious.local"
      assert_response :not_found
    end
  end
end
