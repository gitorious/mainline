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

class UserAutoCompletionsControllerTest < ActionController::TestCase
  def setup
    @user = users(:johan)
    @user.email = "dr_awesome@example.com"
    @user.save!
  end

  context "index" do
    should "find user by login" do
      get :index, :q => "joha", :format => "js"

      assert_equal @user.login, @response.body
    end

    should "find a user by email" do
      get :index, :q => "dr_aw", :format => "js"

      assert_equal @user.login, @response.body
    end

    should "not render emails if user has opted not to have it displayed" do
      @user.update_attribute(:public_email, false)
      get :index, :q => "dr_aw", :format => "js"

      assert_no_match(/email/, @response.body)
    end
  end
end
