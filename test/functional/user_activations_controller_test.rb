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
require "test_helper"

class UserActivationsControllerTest < ActionController::TestCase
  should_render_in_global_context

  should "show pending activation" do
    get :show
    assert_response :success
  end

  should "redirect from pending activation if logged in" do
    login_as :johan
    get :show
    assert_response :redirect
  end

  should "activate user" do
    get :create, :activation_code => users(:moe).activation_code

    assert_redirected_to("/")
    assert_not_nil flash[:notice]
    assert_equal users(:moe), User.authenticate("moe@example.com", "test")
    assert @controller.send(:logged_in?)
  end

  should "flash a message when the activation code is invalid" do
    get :create, :activation_code => "fubar"

    assert_redirected_to("/")
    assert_nil flash[:notice]
    assert_equal "Invalid activation code", flash[:error]
    assert_nil User.authenticate("moe@example.com", "test")
    refute @controller.send(:logged_in?)
  end


  context "in Private Mode" do
    setup do
      @test_settings = Gitorious::Configuration.prepend("public_mode" => false)
    end

    teardown do
      Gitorious::Configuration.prune(@test_settings)
    end

    should "activate user" do
      get :create, :activation_code => users(:moe).activation_code

      assert_redirected_to("/")
      assert !flash[:notice].nil?
      assert_equal users(:moe), User.authenticate("moe@example.com", "test")
    end

    should "flashes a message when the activation code is invalid" do
      get :create, :activation_code => "fubar"

      assert_redirected_to("/")
      assert_nil flash[:notice]
      assert_equal "Invalid activation code", flash[:error]
      assert_nil User.authenticate("moe@example.com", "test")
    end
  end
end
