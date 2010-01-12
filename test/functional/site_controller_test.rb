# encoding: utf-8
#--
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


require File.dirname(__FILE__) + '/../test_helper'

class SiteControllerTest < ActionController::TestCase

  should_render_in_site_specific_context :except => [:about, :faq, :contact]
  should_render_in_global_context :only => [:about, :faq, :contact]

  def alter_gitorious_config(key, value)
    old_value = GitoriousConfig[key]
    GitoriousConfig[key] = value
    yield
    if old_value.nil?

      GitoriousConfig.delete(key)
    else
      GitoriousConfig[key] = old_value
    end
  end

  context "#activity" do
    should "route /activity to public_timeline" do
      assert_recognizes({
          :controller => "site",
          :action => "public_timeline"
        }, "/activities")
    end

    should "render the global activity timeline" do
      get :public_timeline
      assert_response :success
      assert_template "site/index"
    end
  end

  context "#index" do

    context "Logged in users" do
      setup {login_as users(:johan)}

      should "render the dashboard for logged in users" do
        login_as users(:johan)
        get :index
        assert_response :success
        assert_template "site/dashboard"
      end
    end

    context "Anonymous users" do
      should "render the public timeline" do
        alter_gitorious_config("is_gitorious_dot_org", false) do
          get :index
          assert_response :success
          assert_template "site/index"
        end
      end

      should "use the funky layout" do
        alter_gitorious_config("is_gitorious_dot_org", true) do
          get :index
          assert_response :success
          assert_template "layouts/second_generation/application"
        end
      end
    end

    should "not use https if not configured to use https" do
      SslRequirement.expects(:disable_ssl_check?).returns(true).at_least_once
      get :index
      assert_response :success
      assert_select 'form#big_header_login_box_form[action=/sessions]'
    end

    should "use https to login if configured" do
      SslRequirement.expects(:disable_ssl_check?).returns(false).at_least_once
      SslRequirement.expects(:ssl_host).returns("foo.gitorious.org").at_least_once
      get :index
      assert_response :success
      assert_select 'form#big_header_login_box_form[action=https://foo.gitorious.org/sessions]'
    end

    should "gets a list of the most recent projects" do
      get :index
      assert assigns(:projects).is_a?(Array)
    end
  end

  context "#index, with a non-default site" do
    setup do
      paths = ActionController::Base.view_paths
      paths << File.join(Rails.root, "test", "fixtures", "views")
      ActionController::Base.view_paths = paths
      @site = sites(:qt)
    end

    should "render the Site specific template" do
      @request.host = "#{@site.subdomain}.gitorious.test"
      get :index
      assert_response :success
      assert_template "#{@site.subdomain}/index"
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
      GitoriousConfig['is_gitorious_dot_org'] = false
    end

    teardown do
      GitoriousConfig['public_mode'] = true
      GitoriousConfig['is_gitorious_dot_org'] = true
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

