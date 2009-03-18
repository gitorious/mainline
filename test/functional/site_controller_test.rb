# encoding: utf-8
#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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


require File.dirname(__FILE__) + '/../test_helper'

class SiteControllerTest < ActionController::TestCase


  context "#index" do
    should "GETs sucessfully" do
      get :index
      assert_response :success
      assert_template "index"
    end
    
    should "gets a list of the most recent projects" do
      get :index
      assert_equal Project.find(:all, :limit => 5, :order => "id desc"), assigns(:projects)
      assert_equal "max-age=600, private", @response.headers['Cache-Control']
    end
  end
  
  context "#index, with a non-default site" do
    setup do
      @site = sites(:qt)
    end
    
    should "render the Site specific template" do
      @request.host = "#{@site.subdomain}.gitorious.test"
      get :index
      assert_response :success
      assert_template "#{@site.subdomain}/index"
      assert_equal "max-age=600, private", @response.headers['Cache-Control']
    end
    
    should "scope the projects to the current site" do
      @request.host = "#{@site.subdomain}.gitorious.test"
      get :index
      assert_equal @site.projects, assigns(:projects)
    end
  end
  
  context "#dashboard" do
    setup do
      login_as :johan
    end
    
    should "requires login" do
      login_as nil
      get :dashboard
      assert_redirected_to(new_sessions_path)
    end
    
    should "redirects to the user page" do
      get :dashboard
      assert_response :redirect
      assert_redirected_to user_path(users(:johan))
    end
  end
  
  context "in Private Mode" do
    setup do
      GitoriousConfig['public_mode'] = false
    end

    teardown do
      GitoriousConfig['public_mode'] = true
    end

    should "GET / should not show private content in the homepage" do
      get :index
      assert_no_match(/Newest projects/, @response.body)
      assert_no_match(/action\=\"\/search"/, @response.body)
      assert_no_match(/Creating a user account/, @response.body)
      assert_no_match(/\/projects/, @response.body)
      assert_no_match(/\/search/, @response.body)
    end
  end

end

