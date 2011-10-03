# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
require 'test_helper'
require 'capybara/rails'

Capybara.default_driver = :selenium

class OpenidTest < ActionController::IntegrationTest
  include Capybara::DSL
  def allowed_authentication_with_openid_url(url)
      visit "/login"
      click_link 'OpenID'
      fill_in 'OpenID', :with => url
      click_button 'Log in'
      page.has_content? 'Create a new user'
  end

  context "When authenticating through OpenID" do
    should "deny authentication if OpenID server doesn't identify the user" do
      assert !allowed_authentication_with_openid_url('http://localhost:1123/john.doe')
    end

    should "authenticate when authorized by the OpenID provider" do
      assert allowed_authentication_with_openid_url('http://localhost:1123/john.doe?openid.success=true')
    end
  end
end
