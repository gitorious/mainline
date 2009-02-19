# encoding: utf-8
#--
#   Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
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

class CommitsControllerTest < ActionController::TestCase

  context "showing a single commit" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
      @repository.update_attribute(:ready, true)
          
      Repository.any_instance.stubs(:full_repository_path).returns(grit_test_repo("dot_git"))
      Repository.any_instance.stubs(:git).returns(Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true))
      @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
    end
    
    should "get the correct project and repository" do
      get :show, {:project_id => @project.to_param, 
          :repository_id => @repository.to_param, :id => @sha}
      assert_equal @project, assigns(:project)
      assert_equal @repository, assigns(:repository)
    end
    
    should "gets the commit data" do
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => @sha}
      assert_response :success
      assert_equal @repository.git, assigns(:git)
      assert_equal @repository.git.commit(@sha), assigns(:commit)
      assert_not_nil assigns(:diffs)
    end
  
    should "gets the comments for the commit" do
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => @sha}
      assert_equal 0, assigns(:comment_count)
    end
  
    should "defaults to 'inline' diffmode" do
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => @sha}
      assert_equal "inline", assigns(:diffmode)
    end
  
    should "sets sidebyside diffmode" do
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => @sha, :diffmode => "sidebyside" }
      assert_equal "sidebyside", assigns(:diffmode)
    end
    
    should "get it in diff format" do
      get :show, :project_id => @project.slug, 
          :repository_id => @repository.name, :id => @sha, :format => "diff"
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal @repository.git.commit(@sha).diffs.map{|d| d.diff}.join("\n"), @response.body
    end
    
    should "get it in patch format" do
      get :show, :project_id => @project.slug, 
          :repository_id => @repository.name, :id => @sha, :format => "patch"
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal @repository.git.commit(@sha).to_patch, @response.body
    end
  end
  
  context "Routing" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.first
      @repository.update_attribute(:ready, true)
      @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
    end
    
    should "route commits format" do
      assert_recognizes({
        :controller => "commits", 
        :action => "show", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
      }, {:path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}", :method => :get})
      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}", {
        :controller => "commits", 
        :action => "show", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
      })
    end

    should "route diff format" do
      assert_recognizes({
        :controller => "commits", 
        :action => "show", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
        :format => "diff",
      }, {:path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}.diff", :method => :get})
      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}.diff", {
        :controller => "commits", 
        :action => "show", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
        :format => "diff"
      })
    end
    
    should "route patch format" do
      assert_recognizes({
        :controller => "commits", 
        :action => "show", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
        :format => "patch",
      }, {:path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}.patch", :method => :get})
      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}.patch", {
        :controller => "commits", 
        :action => "show", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
        :format => "patch"
      })
    end
  end


  context "listing commits" do

    setup do
      @project = projects(:johans)
      @repository = @project.repositories.first
      @repository.update_attribute(:ready, true)
      Project.expects(:find_by_slug!).with(@project.slug) \
        .returns(@project)
      Repository.expects(:find_by_name_and_project_id!) \
          .with(@repository.name, @project.id).returns(@repository)
      
      Repository.any_instance.stubs(:full_repository_path).returns(grit_test_repo("dot_git"))
      Repository.any_instance.stubs(:git).returns(Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true))
    end

    context "#index" do
      should "GETs page 1 successfully" do
        get :index, {:project_id => @project.slug, 
          :repository_id => @repository.name, :page => nil, :branch => ["master"]}
        assert_response :success
        assert_equal @repository.git.commits("master", 30, 0), assigns(:commits)
      end

      should "GETs page 3 successfully" do
        get :index, {:project_id => @project.slug, 
          :repository_id => @repository.name, :page => nil, :branch => ["master"],
          :page => 3}
        assert_response :success
        assert_equal @repository.git.commits("master", 30, 60), assigns(:commits)
      end

      should "GETs the commits successfully" do
        get :index, {:project_id => @project.slug, 
          :repository_id => @repository.name, :page => nil, :branch => ["master"]}
        assert_response :success
        assert_equal "master", assigns(:root).title
        assert_equal @repository.git, assigns(:git)
        assert_equal @repository.git.commits("master", 30, 0), assigns(:commits)
      end
      
      should "GET the commits of a namedspaced branch successfully" do
        get :index, {:project_id => @project.slug, 
          :repository_id => @repository.name, :page => nil, :branch => ["test", "master"]}
        assert_response :success
        assert_equal "test/master", assigns(:ref)
        assert_equal "test/master", assigns(:root).title
        assert_equal @repository.git, assigns(:git)
        assert_equal @repository.git.commits("test/master", 30, 0), assigns(:commits)
      end
      
      should "have a proper id in the atom feed" do
        #(repo, id, parents, tree, author, authored_date, committer, committed_date, message)
        commit = Grit::Commit.new(mock("repo"), "mycommitid", [], stub_everything("tree"), 
                      stub_everything("author"), Time.now, 
                      stub_everything("comitter"), Time.now, 
                      "my commit message".split(" "))
        @repository.git.expects(:commits).returns([commit])
        commit.stubs(:stats).returns(stub_everything("stats", :files => []))
      
        get :feed, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "master", :format => "atom"}
        assert @response.body.include?(%Q{<id>tag:test.host,2005:Grit::Commit/mycommitid</id>})
      end
    end
  end
end
