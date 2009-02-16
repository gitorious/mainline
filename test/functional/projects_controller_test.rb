# encoding: utf-8
#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

class ProjectsControllerTest < ActionController::TestCase

  def setup
    @project = projects(:johans)
  end
  
  context "Routing" do
    should "recognizes routing like /projectname" do
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
  
    should "recognizes routing like /projectname/repositories" do
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
  
    should "recognizes routing like /projectname/repositories/action" do
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
  
    should "recognizes project actions" do
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
  
    should "recognizes custom routing with format" do
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
    setup do
      @projects = [projects(:johans), projects(:moes)]
    end
  
    should "GET projects/ should be succesful" do
      Project.expects(:find).returns(@projects)
      get :index
      assert_response :success
      assert_equal @projects, assigns(:projects)
      assert_template(("index"))
    end
  
    should "GET projects/new should be succesful" do
      login_as :johan
      get :new
      assert_response :success
      assert_template(("new"))
    end
  
    should "GET projects/new should redirect to new_account_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan
      get :new
      assert_redirected_to(new_account_key_path)
    end
  
    should "GET projects/new should require login" do
      get :new
      assert_response :redirect
      assert_redirected_to(new_sessions_path)
    end
  
    should "POST projects/create with valid data should create project" do
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
  
    should "POST projects/create with valid data should create project, owned by a group" do
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
  
    should "POST projects/create should redirect to new_account_key_path if no keys on user" do
      users(:johan).ssh_keys.destroy_all
      login_as :johan
      post :create
      assert_redirected_to(new_account_key_path)
    end
  
    should "projects/create should require login" do
      post :create
      assert_redirected_to(new_sessions_path)
    end
  
    should "PUT projects/update should require login" do
      put :update
      assert_redirected_to(new_sessions_path)
    end
  
    should "GET projects/N/edit is only for project owner" do
      login_as :moe
      get :edit, :id => projects(:johans).to_param
      assert_match(/you're not the owner of this project/i, flash[:error])
      assert_redirected_to(project_path(projects(:johans)))
    end
  
    should "PUT projects/update can only be done by project owner" do
      project = projects(:johans)
      project.owner = groups(:team_thunderbird)
      project.save!
      login_as :mike
      get :edit, :id => project.to_param
      assert_response :success
    end
  
    should "PUT projects/update can only be done by project group admins" do
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
  
    should "PUT projects/update with valid data should update record" do
      login_as :johan
      project = projects(:johans)
      put :update, :id => project.slug, :project => {:title => "new name", :slug => "foo", :description => "bar"}
      assert_equal project, assigns(:project)
      assert_response :redirect
      assert_redirected_to(project_path(project.reload))
      assert_equal "new name", project.reload.title
    end
  
    should "DELETE projects/destroy should require login" do
      delete :destroy
      assert_response :redirect
      #assert_redirected_to("http://test.host" + new_sessions_path)
      assert_redirected_to(new_sessions_path)
    end
  
    should "DELETE projects/xx is only allowed by project owner" do
      login_as :moe
      delete :destroy, :id => projects(:johans).slug
      assert_redirected_to(projects_path)
      assert_match(/You're not the owner of this project, or the project has clones/i, flash[:error])
    end
  
    should "DELETE projects/xx is only allowed if there's a single repository (mainline)" do
      login_as :johan
      delete :destroy, :id => projects(:johans).slug
      assert_redirected_to(projects_path)
      assert_match(/You're not the owner of this project, or the project has clones/i, flash[:error])
      assert_not_nil Project.find_by_id(1)
    end
  
    should "DELETE projects/destroy should destroy the project" do
      login_as :johan
      repositories(:johans2).destroy
      delete :destroy, :id => projects(:johans).slug
      assert_redirected_to(projects_path)
      assert_nil Project.find_by_id(1)
    end
  
    should "GET projects/show should be success" do
      get :show, :id => projects(:johans).slug
      assert_equal projects(:johans), assigns(:project)
      assert_response :success
    end

    should "GET projects/xx/edit should require login" do
      get :edit, :id => projects(:johans).slug
      assert_response :redirect
      assert_redirected_to(new_sessions_path)
    end

    should "GET projects/xx/edit should be a-ok" do
      login_as(:johan)
      get :edit, :id => projects(:johans).slug
      assert_response :success
    end

    should "GET projects/xx/confirm_delete should require login" do
      get :confirm_delete
      assert_response :redirect
      assert_redirected_to(new_sessions_path)
    end
  
    should "GET projects/xx/confirm_delete fetches the project" do
      login_as(:johan)
      get :edit, :id => projects(:johans).slug
      assert_response :success
      assert_equal projects(:johans), assigns(:project)
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
  
    should "gets a list of the users' groups on edit" do
      get :edit, :id => @project.to_param
      assert_response :success
      assert_equal users(:mike).groups, assigns(:groups)
    end
  
    should "gets a list of the users' groups on update" do
      put :update, :id => @project.to_param, :project => {:title => "foo"}
      assert_equal users(:mike).groups, assigns(:groups)
    end
  
    should "changes the owner" do
      put :update, :id => @project.to_param, :project => {
        :owner_id => @group.id
      }
      assert_redirected_to(project_path(@project))
      assert_equal @group, @project.reload.owner
      assert_equal @group, @project.wiki_repository.owner
    end
  
    should "changes the owner, only if the original owner was a user" do
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
      GitoriousConfig['public_mode'] = false
    end
  
    teardown do
      GitoriousConfig['public_mode'] = true
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
    
    should "redirect if the user is not a site admin on GET #new" do
      login_as :moe
      get :new
      assert_response :redirect
      assert_match(/only site administrators/i, flash[:error])
      assert_redirected_to projects_path
    end
    
    should "be succesful on #new if the user is a site_admin" do
      login_as :johan
      get :new
      assert_nil flash[:error]
      assert_response :success
    end
    
    should "redirect if the user is not a site admin on POST #create" do
      login_as :moe
      post :create, :project => {}
      assert_response :redirect
      assert_match(/only site administrators/i, flash[:error])
      assert_redirected_to projects_path
    end
    
    should "be succesful on POST #create if the user is a site_admin" do
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
end
