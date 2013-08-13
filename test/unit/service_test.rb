# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2012 John VanderPol <john.vanderpol@orbitz.com>
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

class ServiceTest < ActiveSupport::TestCase
  should belong_to(:repository)

  context "Global services" do
    should "find services not associated to a repository" do
      create_web_hook(:url => "http://foo.com", :user => users(:johan))
      assert_equal 1, Service.global_services.size
    end

    should "not find services associated to a repository" do
      create_web_hook(:url => "http://foo.com", :user => users(:johan), :repository => repositories(:johans))
      assert_equal 0, Service.global_services.size
    end

    should "be global" do
      assert build_web_hook(:url => "http://foo.com").global?
      assert !build_web_hook(:url => "http://foo.com", :repository => repositories(:johans)).global?
    end
  end

  context "Keeping track of connection attempts" do
    setup {
      @repository = repositories(:johans)
      @user = users(:johan)
      @hook = create_web_hook(:repository => @repository, :url => "http://gitorious.org/web-hooks")
    }

    should "increment a counter of invalid responses when an error occurs" do
      assert_equal 0, @hook.failed_request_count.to_i
      @hook.failed_connection "302 Moved Permanently"
      assert_equal 1, @hook.failed_request_count
    end

    should "increment successful_request_count when a successful response is received" do
      assert_equal 0, @hook.successful_request_count.to_i
      @hook.successful_connection "200 OK"
      assert_equal 1, @hook.successful_request_count
      assert_equal "200 OK", @hook.last_response
    end
  end
end
