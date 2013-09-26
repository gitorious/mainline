# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "minitest/autorun"
require "config/gitorious_config"
require "app/middlewares/dolt_auth_middleware"
require "fast_test_helper"
require "rack"

if !defined?(Rails)
  class Rails
    class Logger
      def warn(message);end
    end
    def self.logger
      Logger.new
    end
  end
end

class DoltAuthMiddlewareTest < MiniTest::Spec
  describe "Private mode" do
    describe "without private repositories" do
      before do
        @env = {"rack.session" => {}}
        @app = DoltApp.new
        @middleware = DoltAuthMiddleware.new(@app)
        Gitorious.stubs(:public?).returns(false)
        Gitorious.stubs(:private_repositories?).returns(false)
      end

      it "always requires login in private mode" do
        assert_equal 403, @middleware.call(@env).first
      end

      it "allows access logged-in users with private repositories off" do
        @env["rack.session"]["user_id"] = 1
        Gitorious::App.expects(:can_read?).returns(true)
        assert_equal 200, @middleware.call(@env).first
      end
    end

    describe "with private repositories" do
      before do
        @env = {"rack.session" => {}}
        @app = DoltApp.new
        @middleware = DoltAuthMiddleware.new(@app)
        Gitorious.stubs(:public?).returns(false)
        Gitorious.stubs(:private_repositories?).returns(true)
      end

      it "allows access to some" do
        Gitorious::App.stubs(:can_read?).returns(true)
        @env["rack.session"]["user_id"] = 1
        result = @middleware.call(@env)
        assert_equal 200, result.first
      end

      it "denies access" do
        Gitorious::App.stubs(:can_read?).returns(false)
        @env["rack.session"]["user_id"] = 99
        result = @middleware.call(@env)
        assert_equal 403, result.first
      end
    end
  end

  describe "Public mode" do
    before do
      @env = {"rack.session" => {}}
      @app = DoltApp.new
      @middleware = DoltAuthMiddleware.new(@app)
      Gitorious.stubs(:public?).returns(true)
    end

    it "allows logged in users without private repositories" do
      @env["rack.session"]["user_id"] = 99
      Gitorious.stubs(:private_repositories?).returns(false)
      result = @middleware.call(@env)
      assert_equal 200, result.first
    end

    it "requires access to private repositories" do
      Gitorious.stubs(:private_repositories?).returns(true)
      @env["rack.session"]["user_id"] = 1

      Gitorious::App.stubs(:can_read?).returns(true)
      result = @middleware.call(@env)
      assert_equal 200, result.first

      Gitorious::App.stubs(:can_read?).returns(false)
      result = @middleware.call(@env)
      assert_equal 403, result.first
    end
  end

  describe "Non-dolt actions" do
    it "does nothing" do
      env = {}
      app = NonDoltApp.new
      middleware = DoltAuthMiddleware.new(app)
      assert_equal 200, middleware.call(env).first
    end
  end
end
