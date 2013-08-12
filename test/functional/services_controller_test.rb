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

class ServicesControllerTest < ActionController::TestCase
  def setup
    @repository = repositories(:johans)
    @project = @repository.project
  end

  def create_web_hook(params)
    Service::WebHook.create!(params.merge(:repository => @repository))
  end

  should_render_in_site_specific_context

  context "index" do
    should "render web hooks and form" do
      login_as(:johan)

      create_web_hook(:url => "http://somewhere.com", :user => users(:johan))

      get :index, :project_id => @project.to_param, :repository_id => @repository.to_param

      assert_match "http://somewhere.com", @response.body
    end

    should "only be available to repository admin" do
      login_as(:moe)
      create_web_hook(:url => "http://somewhere.com", :user => users(:johan))

      get :index, :project_id => @project.to_param, :repository_id => @repository.to_param

      assert_response :redirect
    end
  end

  context "create" do
    should "create web hook for user" do
      login_as(:johan)
      create_web_hook(:url => "http://somewhere.com", :user => users(:johan))

      post :create, :project_id => @project.to_param, :repository_id => @repository.to_param,
        :service_type => 'web_hook', :service => { :url => "http://elsewhere.com" }

      assert_redirected_to :action => :index
      assert_equal "http://elsewhere.com", @repository.web_hooks.last.url
    end

    should "render form and errors if unsuccessful" do
      login_as(:johan)
      create_web_hook(:url => "http://somewhere.com", :user => users(:johan))

      post :create, :project_id => @project.to_param, :repository_id => @repository.to_param,
        :service_type => 'web_hook', :service => { :url => "http:/meh" }

      assert_response :success
      assert_match "value=\"http:/meh", @response.body
    end

    should "only be available to repository admin" do
      login_as(:moe)
      create_web_hook(:url => "http://somewhere.com", :user => users(:johan))

      post :create, :project_id => @project.to_param, :repository_id => @repository.to_param,
        :service_type => 'web_hook', :service => { :url => "http://elsewhere.com" }

      assert_redirected_to project_repository_path(@project, @repository)
    end
  end

  context "delete" do
    setup do
      create_web_hook(:url => "http://somewhere.com", :user => users(:johan))
    end

    should "remove web hook" do
      login_as(:johan)

      delete :destroy, :project_id => @project.to_param, :repository_id => @repository.to_param, :id => @repository.web_hooks.first.id

      assert_response :redirect
      assert_equal 0, @repository.reload.web_hooks.count
    end

    should "only be available to repository admin" do
      login_as(:moe)

      delete :destroy, :project_id => @project.to_param, :repository_id => @repository.to_param, :id => @repository.web_hooks.first.id

      assert_equal 1, @repository.web_hooks.count
    end
  end
end
