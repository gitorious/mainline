# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
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

class PasswordsControllerTest < ActionController::TestCase
  should_render_in_global_context

  context "update" do
    should "require current user" do
      login_as :moe
      update(users(:johan).to_param, "test", "fubar")
      assert_response :redirect
      assert_redirected_to user_path(users(:moe))
    end

    should "update password when the old one matches" do
      login_as :johan
      user = users(:johan)

      request.env['HTTP_REFERER'] = user_edit_password_path(user)
      update(users(:johan).to_param, "test", "fubar")

      assert_redirected_to(user_edit_password_path(user))
      assert_match(/Your password has been changed/i, flash[:success])
      assert_equal user, User.authenticate(user.email, "fubar")
    end

    should "not update password if the old one is wrong" do
      user = users(:johan)

      login_as :johan
      update(user.to_param, "notthecurrentpassword", "fubar")

      assert_nil flash[:notice]
      assert_match(/does not seem to match/, flash[:error])
      assert_redirected_to(user_edit_password_path(user))
      assert_equal user, User.authenticate(user.email, "test")
      assert_nil User.authenticate(user.email, "fubar")
    end

    should "update password for openid-enabled user" do
      login_as :johan
      user = users(:johan)
      user.update_attribute(:identity_url, "http://johan.someprovider.com/")

      update(users(:johan).to_param, "test", "fubar")

      assert_match(/Your password has been changed/i, flash[:success])
      assert_equal users(:johan), User.authenticate(users(:johan).email, "fubar")
    end
  end

  def update(login, old, new, confirmation = new)
    put(:update, :id => login, :user => {
        :current_password => old,
        :password => new,
        :password_confirmation => confirmation
      })
  end
end
