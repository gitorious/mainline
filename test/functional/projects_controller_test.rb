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

require File.dirname(__FILE__) + "/../test_helper"

class ProjectsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context :only => [:show, :edit, :update, :confirm_delete]
  should_render_in_global_context :except => [:show, :edit, :update, :confirm_delete, :clones]

  should_enforce_ssl_for(:delete, :destroy)
  should_enforce_ssl_for(:get, :clones)
  should_enforce_ssl_for(:get, :confirm_delete)
  should_enforce_ssl_for(:get, :edit)
  should_enforce_ssl_for(:get, :edit_slug)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :new)
  should_enforce_ssl_for(:get, :show)
  should_enforce_ssl_for(:post, :create)
  should_enforce_ssl_for(:put, :edit_slug)
  should_enforce_ssl_for(:put, :preview)
  should_enforce_ssl_for(:put, :update)

  def setup
    setup_ssl_from_config
    @project = projects(:johans)
  end

  context "Routing" do
    should "recognize routing like /projectname" do
      assert_recognizes({
        :controller => "projects", :action => "show", :id => @project.to_param
      }, {:path => "/#{@project.to_param}", :method => :get})
      assert_recognizes({:controller => "projects", :action => "show", :id => @project.to_param},
          {:path => "/#{@project.to_param}/", :method => :get})
      assert_generates("/#{@project.to_param}", {
        :controller => "projects",
        :action => "show",
        :id => @project.to_param
      })
    end

    should "recognize routing like /projectname/repositories" do
      assert_recognizes({
        :controller => "repositories",
        :action => "index",
        :project_id => @project.to_param
      }, {:path => "/#{@project.to_param}/repositories", :method => :get})

      assert_recognizes({
        :controller => "repositories",
        :action => "index",
        :project_id => @project.to_param
      }, {:path => "/#{@project.to_param}/repositories/", :method => :get})
      assert_generates("/#{@project.to_param}/repositories", {
        :controller => "repositories",
        :action => "index",
        :project_id => @project.to_param
      })
    end

    should "recognize routing like /projectname/repositories/action" do
      assert_recognizes({
        :controller => "repositories",
        :action => "new",
        :project_id => @project.to_param
      }, {:path => "/#{@project.to_param}/repositories/new", :method => :get})
      assert_recognizes({
        :controller => "repositories",
        :action => "new",
        :project_id => @project.to_param
      }, {:path => "/#{@project.to_param}/repositories/new", :method => :get})
      assert_generates("/#{@project.to_param}/repositories/new", {
        :controller => "repositories",
        :action => "new",
        :project_id => @project.to_param
      })
    end

    should "recognize project actions" do
      {
        "edit" => [:get, "/edit"],
        "update" => [:put, ""],
        "destroy" => [:delete, ""],
        "confirm_delete" => [:get, "/confirm_delete"],
      }.each do |action, (method, path)|
        assert_recognizes({
          :controller => "projects",
          :action => action,
          :id => @project.to_param
        }, {:path => "/#{@project.to_param}#{path}", :method => method})
        assert_generates("/#{@project.to_param}#{path}", {
          :controller => "projects",
          :action => action,
          :id => @project.to_param
        })
      end
    end

    should "recognize custom routing with format" do
      assert_recognizes({
        :controller => "projects",
        :action => "show",
        :id => @project.to_param,
        :format => "xml"
      }, {:path => "/#{@project.to_param}.xml", :method => :get})
      assert_recognizes({
        :controller => "projects",
        :action => "index",
        :format => "xml"
      }, {:path => "/projects.xml", :method => :get})
      assert_generates("/projects.xml", {
        :controller => "projects",
        :action => "index",
        :format => "xml"
      })
    end
  end

  context "ProjectsController" do
    context "With private repos" do
      setup do
        GitoriousConfig["enable_private_repositories"] = true
        projects(:johans).make_private
      end

      should "filter private projects in index" do
        Project.stubs(:most_active_recently).returns(Project.all)
        get :index
        assert_equal 2, assigns(:projects).length
        assert_equal 2, assigns(:active_recently).length
      end

      should "not render show for private repo for unauthorized user" do
        get :show, :id => projects(:johans).to_param
        assert_response 403
      end

      should "not render show xml for private repo for unauthorized user" do
        get :show, :id => projects(:johans).to_param, :format => :xml
        assert_response 403
      end

      should "render private repo for owner" do
        login_as :johan
        get :show, :id => projects(:johans).to_param
        assert_response 200
      end

      should "not render clones for private repo for unauthorized user" do
        get :clones, :id => projects(:johans).to_param
        assert_response 403
      end

      should "render private repo clones for owner" do
        login_as :johan
        get :clones, :id => projects(:johans).to_param
        assert_response 200
      end

      should "not render private repo edit for unauthorized user" do
        login_as :mike
        get :edit, :id => projects(:johans).to_param
        assert_response 403
      end

      should "render private repo edit for owner" do
        project = projects(:johans)
        project.merge_request_statuses.create!(:name => "Closed", :description => "Whatever", :state => MergeRequest::STATUS_OPEN)
        login_as :johan
        get :edit, :id => projects(:johans).to_param
        assert_response 200
      end

      should "not render private repo edit_slug for unauthorized user" do
        get :edit_slug, :id => projects(:johans).to_param
        assert_response 403
        put :edit_slug, :id => projects(:johans).to_param, :project => { :slug => "yeah" }
        assert_response 403
        assert_not_equal "yeah", projects(:johans).slug
      end

      should "render private repo edit_slug for owner" do
        login_as :johan
        get :edit_slug, :id => projects(:johans).to_param
        assert_response 200
        put :edit_slug, :id => projects(:johans).to_param, :project => { :slug => "yeah" }
        assert_response 302
      end

      should "not render private repo update for unauthorized user" do
        login_as :mike
        put :update, :id => projects(:johans).to_param, :project => {}
        assert_response 403
      end

      should "render private repo update for owner" do
        login_as :johan
        put :update, :id => projects(:johans).to_param, :project => { :slug => "  " }
        assert_response 200
      end

      should "not render private repo delete confirmation for unauthorized user" do
        login_as :mike
        get :confirm_delete, :id => projects(:johans).to_param
        assert_response 403
      end

      should "render private repo delete confirmation for owner" do
        login_as :johan
        get :confirm_delete, :id => projects(:johans).to_param
        assert_response 200
      end

      should "disallow unauthorized user to destroy project" do
        login_as :mike
        delete :destroy, :id => projects(:johans).slug
        assert_response 403
      end

      should "not display edit permissions link to non-admin" do
        get :show, :id => projects(:johans).to_param
        assert_no_match /Manage access/, @response.body
      end

      should "display edit permissions link for admin" do
        login_as :johan
        get :show, :id => projects(:johans).to_param
        assert_match /Manage access/, @response.body
      end

      should "create private project" do
        login_as :johan

        assert_difference("Project.count") do
          post :create, :project => {
            :title => "project x",
            :slug => "projectx",
            :description => "projectx's description",
            :owner_type => "User"
          },
          :private_project => "1"
        end

        assert can_read?(users(:johan), Project.last)
        assert !can_read?(users(:mike), Project.last)
        assert !can_read?(nil, Project.last)
      end

      should "create public project" do
        login_as :johan

        assert_difference("Project.count") do
          post :create, :project => {
            :title => "project x",
            :slug => "projectx",
            :description => "projectx's description",
            :owner_type => "User"
          }
        end

        assert can_read?(nil, Project.last)
      end

    end

    context "with disabled private repos" do
      setup do
        GitoriousConfig["enable_private_repositories"] = false
      end

      should "not display edit acccess link to owner" do
        login_as :johan
        get :show, :id => projects(:johans).to_param
        assert_no_match /Manage access/, @response.body
      end

      should "not allow creating private project" do
        login_as :johan

        assert_difference("Project.count") do
          post :create, :project => {
            :title => "project x",
            :slug => "projectx",
            :description => "projectx's description",
            :owner_type => "User"
          },
          :private => true
        end

        assert can_read?(nil, Project.last)
      end
    end

    should "PUT to preview" do
      put :preview, :id => projects(:johans).to_param, :project => { :description => "Hey" }
      assert_response 200
    end

    should "GET projects/ succesfully" do
      get :index
      assert_response :success
      assert !assigns(:projects).empty?
      assert_template(("index"))
    end

    should "GET projects/new succesfully" do
      login_as :johan
      get :new
      assert_response :success
      assert_template(("new"))
    end

    should "redirect GET projects/new to new_user_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan
      get :new
      assert_redirected_to(new_user_key_path(users(:johan)))
    end

    should "require login for GET projects/new" do
      get :new
      assert_response :redirect
      assert_redirected_to(new_sessions_path)
    end

    should "create project for POST projects/create with valid data" do
      login_as :johan
      assert_difference("Project.count") do
        post :create, :project => {
          :title => "project x",
          :slug => "projectx",
          :description => "projectx's description",
          :owner_type => "User"
        }
      end
      assert_response :redirect
      assert_redirected_to(new_project_repository_path(assigns(:project)))

      assert_equal users(:johan), assigns(:project).user
      assert_equal users(:johan), assigns(:project).owner
    end

    should "create project with full form payload" do
      login_as :johan

      assert_difference("Project.count") do
        post(:create, {
               "utf8" => "✓",
               "authenticity_token" => "Whb/NuCNXbRGmUdOmTMMVOjP9MEzfp2IxVPEsEhIoJs=",
               "project" => {
                 "title" => "Big blob",
                 "slug" => "big-blob",
                 "owner_type" => "User",
                 "tag_list" => "",
                 "license" => "Academic Free License v3.0",
                 "home_url" => "",
                 "mailinglist_url" => "",
                 "bugtracker_url" => "",
                 "wiki_enabled" => "1",
                 "description" => "My new project"},
               "commit" => "Create project"})
      end
    end

    should "re-render the template for POST projects/create with invalid data" do
      login_as :johan
      assert_no_difference("Project.count") do
        post :create, :project => {}
      end
      assert_response :success
      assert_template "projects/new"
      assert !assigns(:project).valid?
    end

    should "Create an event when successfully POSTing to create" do
      login_as :johan
      assert_difference("Event.count") do
        post :create, :project => {
          :title => "project x",
          :slug => "projectx",
          :description => "projectx's description",
          :owner_type => "User"
        }
      end
      assert_equal 1, assigns(:project).reload.events.count
      event = assigns(:project).events.first
      assert_equal Action::CREATE_PROJECT, event.action
    end

    should "render an error page if the create was throttled" do
      login_as :johan
      Project.any_instance.expects(:save).raises(RecordThrottling::LimitReachedError)
      assert_no_difference("Project.count") do
        post :create, :project =>  {
          :title => "project x",
          :slug => "projectx",
          :description => "projectx's description",
          :owner_type => "User"
        }
      end
      assert_response :precondition_failed
      assert_select "h1", /slow down/i
      assert_select "p", /denied your request due to excessive usage/i
    end

    should "create project, owned by a group when POST projects/create with valid data" do
      login_as :johan
      group = groups(:team_thunderbird)
      group.add_member(users(:johan), Role.admin)
      assert_difference("Project.count") do
        post :create, :project => {
          :title => "project x",
          :slug => "projectx",
          :description => "projectx's description",
          :owner_type => "Group",
          :owner_id => group.id
        }
      end
      assert_response :redirect
      assert_redirected_to(new_project_repository_path(assigns(:project)))

      assert_equal users(:johan), assigns(:project).user
      assert_equal group, assigns(:project).owner
    end

    should "redirect to new_user_key_path when POST projects/create if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan
      post :create
      assert_redirected_to(new_user_key_path(users(:johan)))
    end

    should "redirect to acceptance of EULA when POST projects/create if this has not been done" do
      users(:johan).update_attribute(:aasm_state, "pending")
      login_as :johan
      post :create
      assert_redirected_to(user_license_path(users(:johan)))
    end

    should "require login for projects/create" do
      post :create
      assert_redirected_to(new_sessions_path)
    end

    should "require login for PUT projects/update" do
      put :update
      assert_redirected_to(new_sessions_path)
    end

    should "only allow project owner to GET projects/N/edit" do
      login_as :moe
      get :edit, :id => projects(:johans).to_param
      assert_match(/you are not the owner of this project/i, flash[:error])
      assert_redirected_to(project_path(projects(:johans)))
    end

    should "allow project owner to PUT projects/update" do
      project = projects(:johans)
      project.owner = groups(:team_thunderbird)
      project.save!
      login_as :mike
      get :edit, :id => project.to_param
      assert_response :success
    end

    should "only allow project group admins to PUT projects/update" do
      project = projects(:johans)
      project.owner = groups(:team_thunderbird)
      project.save!
      login_as :mike
      put :update, :id => project.to_param, :project => {
        :description => "bar"
      }
      assert_equal "bar", assigns(:project).reload.description
      assert_redirected_to(project_path(project))
    end

    should "deny non-project admins access to edit slug" do
      login_as :moe
      get :edit_slug, :id => projects(:johans).to_param
      assert_response :redirect
    end

    should "allow project admins to change the slug" do
      login_as :johan
      @project = projects(:johans)
      get :edit_slug, :id => @project.to_param
      assert_response :success
      put :edit_slug, :id => @project.to_param, :project => {:slug => "another_one"}
      assert_redirected_to :action => :show, :id => @project.reload.slug
      assert_equal "another_one", projects(:johans).reload.slug
    end

    should "update record when PUT projects/update with valid data" do
      login_as :johan
      project = projects(:johans)
      put :update, :id => project.slug, :project => {:title => "new name", :slug => "foo", :description => "bar"}
      assert_equal project, assigns(:project)
      assert_response :redirect
      assert_redirected_to(project_path(project.reload))
      assert_equal "new name", project.reload.title
    end

    should "render a preview of the project information when PUT preview" do
      login_as :johan
      project = projects(:johans)
      put :preview, :id => project.to_param, :project => {:title => "something new", :description => "This is a long description"}, :format => "js"
      assert_response :success
    end

    should "require login to DELETE projects/destroy" do
      delete :destroy
      assert_response :redirect
      assert_redirected_to new_sessions_path
    end

    should "only allow project owner to DELETE projects/xx" do
      login_as :moe
      delete :destroy, :id => projects(:johans).slug
      assert_redirected_to(projects_path)
      assert_match(/You are not the owner of this project, or the project has clones/i, flash[:error])
    end

    should "only allow DELETE projects/xx if there is a single repository (mainline)" do
      login_as :johan
      delete :destroy, :id => projects(:johans).slug
      assert_redirected_to(projects_path)
      assert_match(/You are not the owner of this project, or the project has clones/i, flash[:error])
      assert_not_nil Project.find_by_id(1)
    end

    should "destroy the project when DELETE projects/destroy" do
      login_as :johan
      repositories(:johans2).destroy
      delete :destroy, :id => projects(:johans).slug
      assert_redirected_to(projects_path)
      assert_nil Project.find_by_id(1)
    end

    should "succesfully GET projects/show" do
      get :show, :id => projects(:johans).slug
      assert_equal projects(:johans), assigns(:project)
      assert_response :success
    end

    should "require login for GET projects/xx/edit" do
      get :edit, :id => projects(:johans).slug
      assert_response :redirect
      assert_redirected_to(new_sessions_path)
    end

    should "successfully GET projects/xx/edit" do
      login_as(:johan)
      get :edit, :id => projects(:johans).slug
      assert_response :success
    end

    should "require login for GET projects/xx/confirm_delete" do
      get :confirm_delete
      assert_response :redirect
      assert_redirected_to(new_sessions_path)
    end

    should "fetch the project when GET projects/xx/confirm_delete" do
      login_as(:johan)
      get :edit, :id => projects(:johans).slug
      assert_response :success
      assert_equal projects(:johans), assigns(:project)
    end

    should "fetch group and user clones when GET show" do
      get :show, :id => projects(:johans).slug
      assert_response :success
      assert_not_nil assigns(:group_clones)
      assert_not_nil assigns(:user_clones)
    end

    should "render all the clone repositories" do
      get :clones, :id => projects(:johans).slug, :format => "js"
      assert_response :success
      assert_not_nil assigns(:group_clones)
      assert_not_nil assigns(:user_clones)
      assert_template "_repositories"
    end

    should "respond with etag based on the event when GET show" do
      50.times do |i|
        projects(:johans).events.create!({
          :action => Action::CREATE_BRANCH,:target => repositories(:johans),
          :data => "branch-#{i}", :body => "branch-#{i}", :user => users(:moe)
        })
      end

      get :show, :id => projects(:johans).slug
      page_one_etag = @response.etag
      assert_not_nil page_one_etag

      get :show, :id => projects(:johans).slug, :page => 2
      assert_not_equal page_one_etag, @response.etag
    end

    context "project event pagination" do
      setup { @params = { :id => projects(:johans).to_param } }
      should_scope_pagination_to(:show, Event)
    end
  end

  context "Changing owner" do
    setup do
      @project = projects(:johans)
      @project.owner = users(:mike)
      @project.save
      @group = users(:mike).groups.first
      login_as :mike
    end

    should "get a list of the users' groups on edit" do
      group = groups(:a_team)
      mike = users(:mike)
      assert !group.member?(mike)
      group.add_member(mike, Role.member)
      get :edit, :id => @project.to_param
      assert_response :success
      assert !assigns(:groups).include?(group), "included group where user is only member"
      assert_equal Team.by_admin(mike), assigns(:groups)
    end

    should "only get a list of groups user is admin in on update" do
      group = groups(:a_team)
      assert !group.member?(users(:mike))
      group.add_member(users(:mike), Role.member)
      put :update, :id => @project.to_param, :project => {:title => "foo"}
      assert_response :redirect
      assert !assigns(:groups).include?(group), "included group where user is only member"
      assert_equal users(:mike).groups.select{|g| admin?(users(:mike), g) }, assigns(:groups)
    end

    should "change the owner" do
      put :update, :id => @project.to_param, :project => {
        :owner_id => @group.id
      }
      assert_redirected_to(project_path(@project))
      assert_equal @group, @project.reload.owner
      assert_equal @group, @project.wiki_repository.owner
    end

    should "change the owner only if original owner was a user" do
      @project.owner = @group
      @project.save!
      new_group = Group.create!(:name => "temp")
      new_group.add_member(users(:mike), Role.admin)

      put :update, :id => @project.to_param, :project => {
        :owner_id => new_group.id
      }
      assert_redirected_to(project_path(@project))
      assert_equal @group, @project.reload.owner
    end
  end

  context "in Private Mode" do
    setup do
      GitoriousConfig["public_mode"] = false
    end

    teardown do
      GitoriousConfig["public_mode"] = true
    end

    should "GET /projects" do
      get :index
      assert_redirected_to(root_path)
      assert_match(/Action requires login/, flash[:error])
    end
  end

  context "when only admins are allowed to create new projects" do
    setup do
      GitoriousConfig["only_site_admins_can_create_projects"] = true
      users(:johan).update_attribute(:is_admin, true)
      users(:moe).update_attribute(:is_admin, false)
    end

    teardown do
      GitoriousConfig["only_site_admins_can_create_projects"] = false
    end

    should "redirect regular users to the project approval workflow" do
      login_as :moe
      get :new
      assert_response :redirect
      assert_redirected_to "/admin/project_proposals/new"
    end

    should "succesfully GET #new if the user is a site_admin" do
      login_as :johan
      get :new
      assert_nil flash[:error]
      assert_response :success
    end

    should "render licenses with description" do
      login_as :johan
      ProjectLicense.stubs(:all).returns([ProjectLicense.new("MIT", "The liberal one"),
                                          ProjectLicense.new("BSD", "Keep the copyright")])

      get :new

      assert_match /<option [^>]*data-description="The liberal one"[^>]*>MIT/, @response.body
      assert_match /description="Keep the copyright"[^>]*>BSD/, @response.body
    end

    should "render license descriptions without newlines" do
      login_as :johan
      ProjectLicense.stubs(:all).returns([ProjectLicense.new("MIT", "The liberal\none"),
                                          ProjectLicense.new("BSD", "Keep the\ncopyright")])

      get :new

      assert_match /description="[^\n]*"[^>]*>BSD/, @response.body
      assert_match /The liberal one/, @response.body
    end

    should "pre-select default license" do
      login_as :johan
      ProjectLicense.stubs(:default).returns("BSD")
      ProjectLicense.stubs(:all).returns(%w[MIT BSD GPL].collect { |l| ProjectLicense.new(l) })

      get :new

      assert_match /selected="selected"[^>]*>BSD/, @response.body
    end

    should "redirect if the user is not a site admin on POST #create" do
      login_as :moe
      post :create, :project => {}
      assert_response :redirect
      assert_match(/only site administrators/i, flash[:error])
      assert_redirected_to projects_path
    end

    should "succesfully POST #create if the user is a site_admin" do
      login_as :johan
      post :create, :project => {
        :title => "project x",
        :slug => "projectx",
        :description => "projectx's description",
        :owner_type => "User"
      }
      assert_nil flash[:error]
      assert_response :redirect
      assert_redirected_to new_project_repository_path(assigns(:project))
    end
  end

  context "with a site specific layout" do
    should "render with the application layout if there is no containing site" do
      get :show, :id => projects(:johans).to_param
      assert_response :success
      assert_equal "layouts/application", @response.layout
      assert_not_nil assigns(:current_site)
      assert_not_nil @controller.send(:current_site)
      assert_equal Site.default.title, @controller.send(:current_site).title
    end

    should "redirect to the proper subdomain if the current site has one" do
      @request.host = "gitorious.test"
      get :show, :id => projects(:thunderbird).to_param
      assert_response :redirect
      assert_redirected_to project_path(projects(:thunderbird),
        :only_path => false, :host => "#{sites(:qt).subdomain}.gitorious.test")
    end

    should "redirect to the proper subdomain if the current site has one and we are using www" do
      @request.host = "www.gitorious.test"
      get :show, :id => projects(:thunderbird).to_param
      assert_response :redirect
      assert_redirected_to project_path(projects(:thunderbird),
        :only_path => false, :host => "#{sites(:qt).subdomain}.gitorious.test")
    end

    should "redirect to the main domain if the current_site does not have a subdomain" do
      @request.host = "qt.gitorious.test"
      get :show, :id => projects(:johans).to_param
      assert_response :redirect
      assert_redirected_to project_path(projects(:johans), :only_path => false,
                            :host => "gitorious.test")
    end
  end

  context "With private repos and LDAP authorization" do
    setup do
      GitoriousConfig["enable_private_repositories"] = true
      Team.group_implementation = LdapGroup
      @group = ldap_groups(:first_ldap_group)
      @user = users(:moe)
      LdapGroup.stubs(:groups_for_user).with(@user).returns([@group])
      @project = projects(:johans)
      @project.make_private
      @project.add_member(@group)
    end

    teardown do
      GitoriousConfig["enable_private_repositories"] = false
      Team.group_implementation = Group
    end

    should "filter private projects in index" do
      login_as @user
      get :show, :id => @project.to_param
      assert_response :success
    end

    should "deny access for users who are not member of the LDAP group" do
      LdapGroup.stubs(:groups_for_user).with(users(:mike)).returns([])
      login_as users(:mike)
      get :show, :id => @project.to_param
      assert_response 403
    end
  end
end
