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

class CommentsControllerTest < ActionController::TestCase
  
  should_render_in_site_specific_context

  def setup
    @project = projects(:johans)
    @repository = repositories(:johans)
  end
  
  context "#index" do
    should "scopes to project.repositories" do
      get :index, :project_id => @project.to_param, 
        :repository_id => @repository.to_param
      assert_response :success
      assert !assigns(:comments).include?(comments(:moes_repos))
    end
  end
  
  context "#new" do    
    should "requires login" do
      session[:user_id] = nil
      get :new, :project_id => @project.slug, 
        :repository_id => @repository.name
      assert_redirected_to (new_sessions_path)
    end
    
    should "is successfull" do
      login_as :johan
      get :new, :project_id => @project.slug, 
        :repository_id => @repository.name
      assert_response :success
      assert_equal @repository, assigns(:comment).target
    end
  end
  
  context "#create" do    
    should "requires login" do
      session[:user_id] = nil
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => {}
      assert_redirected_to (new_sessions_path)
    end
    
    should "scopes to the repository" do
      login_as :johan
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => { :body => "blabla" }
      assert_equal @repository, assigns(:comment).target
    end
    
    should "assigns the comment to the current_user" do
      login_as :johan
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => { :body => "blabla" }
      assert_equal users(:johan), assigns(:comment).user
    end
    
    should "creates the record on successful data" do
      login_as :johan
      assert_difference("Comment.count") do
        get :create, :project_id => @project.slug, 
          :repository_id => @repository.name, :comment => { :body => "moo" }
        assert_redirected_to (project_repository_comments_path(@project, @repository))
        assert_match(/your comment was added/i, flash[:success])
      end
    end
    
    should "it re-renders on invalid data" do
      login_as :johan
      get :create, :project_id => @project.slug, 
        :repository_id => @repository.name, :comment => {:body => nil}
      assert_response :success
      assert_template("comments/new")
    end    
  end
  
  context 'preview' do
    should 'render a preview of the comment' do
      login_as :johan
      post :preview, :project_id => @project.slug, :repository_id => @repository.name, :comment => {:body => 'Foo'}
      assert_response :success
      assert_template("comments/preview")
    end
  end
end
