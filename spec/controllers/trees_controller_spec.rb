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

require File.dirname(__FILE__) + '/../spec_helper'

describe TreesController do
  
  describe "routing" do
    it "recognizes a single glob with a format" do
      pending "fix rails bug #1939"
      params_from(:get, "/proj/repo/archive/foo.tar.gz").should == {
        :controller => "trees",
        :action => "archive", 
        :project_id => "proj",
        :repository_id => "repo",
        :branch => ["foo"],
        :format => "tar.gz",        
      }
      params_from(:get, "/proj/repo/archive/foo.zip").should == {
        :controller => "trees",
        :action => "archive", 
        :project_id => "proj",
        :repository_id => "repo",
        :branch => ["foo"],
        :format => "zip",
      }
    end
    
    it "recognizes multiple globs with a format" do
      pending "fix rails bug #1939"
      params_from(:get, "/proj/repo/archive/foo/bar.zip").should == {
        :controller => "trees",
        :action => "archive", 
        :project_id => "proj",
        :repository_id => "repo",
        :branch => ["foo", "bar"],
        :format => "zip",
      }
      params_from(:get, "/proj/repo/archive/foo/bar.tar.gz").should == {
        :controller => "trees",
        :action => "archive", 
        :project_id => "proj",
        :repository_id => "repo",
        :branch => ["foo", "bar"],
        :format => "tar.gz",        
      }
    end
  end
  
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
    @repository.stubs(:full_repository_path).returns(repo_path)

    Project.expects(:find_by_slug!).with(@project.slug) \
      .returns(@project)
    Repository.expects(:find_by_name_and_project_id!) \
        .with(@repository.name, @project.id).returns(@repository)
    
    @repository.stubs(:has_commits?).returns(true)

    @git = stub_everything("Grit mock")
    @repository.stubs(:git).returns(@git)
    @head = mock("master branch")
    @head.stubs(:name).returns("master")
    @repository.stubs(:head_candidate).returns(@head)
  end
  
  describe "#index" do
    it "redirects to the master head, if not :id given" do
      head = mock("a branch")
      head.stubs(:name).returns("somebranch")
      @repository.expects(:head_candidate).returns(head)

      get :index, :project_id => @project.slug, :repository_id => @repository.name
      response.should redirect_to(project_repository_tree_path(@project, @repository, ["somebranch"]))
    end
  end
  
  describe "#show" do
    it "GETs successfully" do
      tree_mock = mock("tree")
      tree_mock.stubs(:id).returns("123")
      @commit_mock = mock("commit")
      @commit_mock.stubs(:tree).returns(tree_mock)
      @git.expects(:commit).with("master").returns(@commit_mock)
      @git.expects(:tree).with(tree_mock.id, ["foo/bar/"]).returns(tree_mock)
      @git.stubs(:get_head).returns(stub("head", :name => "master"))
      
      get :show, :project_id => @project.to_param, 
        :repository_id => @repository.to_param, :branch_and_path => ["master", "foo", "bar"]
      
      response.should be_success
      assigns(:git).should == @git
      assigns(:tree).should == tree_mock
      assigns(:ref).should == "master"
      assigns(:path).should == ["foo", "bar"]
    end
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.expects(:commit).with("a"*40).returns(nil)
      @git.stubs(:get_head).returns(stub("head", :name => "master"))
      get :show, :project_id => @project.slug, 
        :repository_id => @repository.name, :branch_and_path => ["a"*40, "foo"]
      
      response.should redirect_to(project_repository_tree_path(@project, @repository, ["HEAD", "foo"]))
    end
    
    it "sets a pseudo-head if the tree ref is a sha" do
      ref = "a"*20 + "1"*20
      tree_mock = mock("tree")
      tree_mock.stubs(:id).returns("123")
      @commit_mock = mock("commit")
      @commit_mock.stubs(:tree).returns(tree_mock)
      @commit_mock.stubs(:id_abbrev).returns(ref[0..7])
      @git.expects(:get_head).with(ref).returns(nil)
      @git.expects(:commit).with(ref).returns(@commit_mock)
      @git.expects(:tree).with(tree_mock.id, []).returns(tree_mock)
      
      get :show, :project_id => @project.to_param, 
        :repository_id => @repository.to_param, :branch_and_path => [ref]
        
      response.should be_success
      assigns(:root).breadcrumb_parent.title.should == ref[0..7]
    end
  end
  
  describe "Archive downloads" do
    before(:each) do
      ActiveMessaging::Gateway.connection.clear_messages
    end
    
    it "returns the correct for an existing cached tarball" do
      commit = mock("commit")
      commit.stubs(:id).returns("abc123")
      @git.stubs(:commit).returns(commit)
      cached_path = File.join(GitoriousConfig["archive_cache_dir"], "#{@repository.hashed_path}-#{commit.id}.tar.gz")
      File.expects(:exist?).with(cached_path).returns(true)
      
      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[foo bar], :archive_format => "tar.gz"

      response.should be_success      
      response.headers["X-Sendfile"].should == cached_path
      response.headers["Content-Type"].should == "application/x-gzip; charset=utf-8"
      exp_filename = "#{@repository.owner.to_param}-#{@repository.to_param}-foo_bar.tar.gz"
      response.headers["Content-Disposition"].should == "Content-Disposition: attachment; file=\"#{exp_filename}\""
    end
    
    it "enqueues a job when the tarball isn't cached" do
      commit = mock("commit")
      commit.stubs(:id).returns("abc123")
      @git.stubs(:commit).returns(commit)
      cached_path = File.join(GitoriousConfig["archive_cache_dir"], "#{@repository.hashed_path}-#{commit.id}.tar.gz")
      File.expects(:exist?).with(cached_path).returns(false)
      
      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[foo bar], :archive_format => "tar.gz"

      response.code.to_i.should == 202 # Accepted
      response.body.should match(/is currently being generated, try again later/)
      response.headers["Content-Type"].should == "text/plain; charset=utf-8"
      #response.headers["Content-Disposition"].should == "Content-Disposition: inline; file=\"in_progress.txt\""
      
      msg = ActiveMessaging::Gateway.connection.find_message("/queue/GitoriousRepositoryArchiving", /#{commit.id}/)
      msg.should_not be_nil
      msg_hash = ActiveSupport::JSON.decode(msg.body)
      msg_hash["full_repository_path"].should == @repository.full_repository_path
      msg_hash["output_path"].should == cached_path
      msg_hash["commit_sha"].should == commit.id
      msg_hash["format"].should == "tar.gz"
    end
  end

end
