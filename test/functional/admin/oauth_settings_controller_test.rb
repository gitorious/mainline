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

class Admin::OauthSettingsControllerTest < ActionController::TestCase
  def setup
    setup_ssl_from_config
  end

  context "On get to edit" do
    should "grant site admins access" do
      login_as(:johan)
      get :edit, :project_id => projects(:johans).slug
      assert_response :success
    end

    should "deny access to non admin users" do
      login_as(:mike)
      get :edit, :project_id => projects(:johans).slug
      assert_response :redirect
    end
  end

  context "On put to update" do
    setup {
      @project = projects(:johans)
    }

    should "accept new oauth settings and redirect" do
      login_as :johan
      new_settings = {
        :path_prefix      => "/foo",
        :signoff_key      => "kee",
        :signoff_secret   => "secret",
        :site             => "http://oauth.example.com/"
      }
      put :update, :project_id => @project.to_param, :oauth_settings => new_settings
      assert_redirected_to :action => :edit, :project_id => @project.to_param
      assert_equal new_settings, @project.reload.oauth_settings
    end
  end

  context "On get to show" do
    should "redirect to edit" do
      project = projects(:johans)
      login_as :johan
      get :show, :project_id => project.to_param
      assert_redirected_to :action => :edit, :project_id => project.to_param
    end
  end
end
