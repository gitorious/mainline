# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class SslRedirectionTest < ActionController::TestCase
  context "Admin::OauthSettingsController" do
    setup { @controller = Admin::OauthSettingsController.new }
    should_enforce_ssl_for(:get, :edit)
    should_enforce_ssl_for(:get, :show)
    should_enforce_ssl_for(:put, :update)
  end

  context "Admin::RepositoriesController" do
    setup { @controller = Admin::RepositoriesController.new }
    should_enforce_ssl_for(:get, :index)
    should_enforce_ssl_for(:put, :recreate)
  end

  context "Admin::UsersController" do
    setup { @controller = Admin::UsersController.new }
    should_enforce_ssl_for(:get, :index)
    should_enforce_ssl_for(:get, :new)
    should_enforce_ssl_for(:post, :create)
    should_enforce_ssl_for(:post, :reset_password)
    should_enforce_ssl_for(:put, :suspend)
    should_enforce_ssl_for(:put, :unsuspend)
  end
end
