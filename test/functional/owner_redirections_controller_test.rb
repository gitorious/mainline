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

class OwnerRedirectionsControllerTest < ActionController::TestCase
  def setup
    setup_ssl_from_config
  end

  context "users" do
    setup do
      @user = users(:johan)
      @project = @user.projects.first
      @repository = @project.repositories.first
    end

    should "redirect project" do
      slug = @project.to_param
      get :show, :user_id => @user.to_param, :slug => slug

      assert_redirected_to("/#{slug}")
    end

    should "redirect project/repository" do
      project = @repository.project

      get :show, :user_id => @user.to_param, :slug => "#{project.to_param}/#{@repository.to_param}/refs"

      assert_redirected_to("/#{project.to_param}/#{@repository.to_param}/refs")
    end

    should "redirect repository" do
      slug = "#{@repository.to_param}"
      get :show, :user_id => @user.to_param, :slug => slug

      assert_redirected_to("/#{@project.to_param}/#{slug}")
    end

    should "redirect repository action" do
      slug = "#{@repository.to_param}/merge_requests/1/edit"
      get :show, :user_id => @user.to_param, :slug => slug

      assert_redirected_to("/#{@project.to_param}/#{slug}")
    end

    should "404 for non-existent project/repository" do
      get :show, :user_id => @user.to_param, :slug => "/something"

      assert_response 404
    end

    should "404 for non-existent user" do
      get :show, :user_id => "someone", :slug => @project.to_param

      assert_response 404
    end

    should "404 for project not belonging to user" do
      project = users(:moe).projects.first
      get :show, :user_id => @user.to_param, :slug => project.to_param

      assert_response 404
    end
  end

  context "groups" do
    setup do
      @group = groups(:team_thunderbird)
      @repository = repositories(:johans2)
    end

    should "redirect repository" do
      slug = "#{@repository.to_param}"
      get :show, :group_id => @group.to_param, :slug => slug

      assert_redirected_to("/#{@repository.project.to_param}/#{slug}")
    end
  end
end
