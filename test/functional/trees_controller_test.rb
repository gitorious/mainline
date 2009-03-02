# encoding: utf-8
#--
#   Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
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

class TreesControllerTest < ActionController::TestCase
  
  context "routing" do
    should_eventually "recognizes a single glob with a format" do
      pending "fix rails bug #1939"
      assert_recognizes({
        :controller => "trees",
        :action => "archive", 
        :project_id => "proj",
        :repository_id => "repo",
        :branch => ["foo"],
        :format => "tar.gz",        
      }, "/proj/repo/archive/foo.tar.gz")
      assert_recognizes({
        :controller => "trees",
        :action => "archive", 
        :project_id => "proj",
        :repository_id => "repo",
        :branch => ["foo"],
        :format => "zip",
      }, "/proj/repo/archive/foo.zip")
    end
    
    should_eventually "recognizes multiple globs with a format" do
      pending "fix rails bug #1939"
      assert_recognizes({
        :controller => "trees",
        :action => "archive", 
        :project_id => "proj",
        :repository_id => "repo",
        :branch => ["foo", "bar"],
        :format => "zip",
      }, "/proj/repo/archive/foo/bar.zip")
      assert_recognizes({
        :controller => "trees",
        :action => "archive", 
        :project_id => "proj",
        :repository_id => "repo",
        :branch => ["foo", "bar"],
        :format => "tar.gz",        
      }, "/proj/repo/archive/foo/bar.tar.gz")
    end
  end
  
  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @repository.update_attribute(:ready, true)
    
    Repository.any_instance.stubs(:full_repository_path).returns(grit_test_repo("dot_git"))
    Repository.any_instance.stubs(:git).returns(Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true))
  end
  
  context "#index" do
    should "redirects to the master head, if not :id given" do
      get :index, :project_id => @project.slug, :repository_id => @repository.name
      assert_redirected_to(project_repository_tree_path(@project, @repository, ["master"]))
    end
  end
  
  context "#show" do
    should "GETs successfully" do
      get :show, :project_id => @project.to_param, 
        :repository_id => @repository.to_param, :branch_and_path => ["master", "lib", "grit"]
      
      assert_response :success
      assert_equal @repository.git.tree("81a18c36ebe04e406ab84ccc911d79e65e14d1c0"), assigns(:tree)
      assert_equal "master", assigns(:ref)
      assert_equal ["lib", "grit"], assigns(:path)
    end
    
    should "redirects to HEAD if provided sha was not found (backwards compat)" do
      get :show, :project_id => @project.slug, 
        :repository_id => @repository.name, :branch_and_path => ["a"*40, "foo"]
      
      assert_redirected_to(project_repository_tree_path(@project, @repository, ["HEAD", "foo"]))
    end
    
    should "sets a pseudo-head if the tree ref is a sha" do
      ref = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"      
      get :show, :project_id => @project.to_param, 
        :repository_id => @repository.to_param, :branch_and_path => [ref]
        
      assert_response :success
      assert_equal ref[0..6], assigns(:root).breadcrumb_parent.title
    end
    
    should "support browsing a namespaced branch" do
      get :show, :project_id => @project.to_param, :repository_id => @repository.to_param, 
            :branch_and_path => ["test", "master", "lib"]
        
      assert_response :success
      assert_equal "test/master", assigns(:root).breadcrumb_parent.breadcrumb_parent.title
      assert_equal ["lib"], assigns(:path)
    end
    
    should 'cache the tree' do
      get :show, :project_id => @project.to_param, :repository_id => @repository.to_param, 
            :branch_and_path => ["test", "master", "lib"]
        
      assert_response :success
      assert_equal "max-age=30, private", @response.headers['Cache-Control']
    end
  end
  
  context "Archive downloads" do
    setup do
      ActiveMessaging::Gateway.connection.clear_messages
      @master_sha = "ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a"
      @test_master_sha = "2d3acf90f35989df8f262dc50beadc4ee3ae1560"
    end
    
    should "returns the correct for an existing cached tarball" do
      cached_path = File.join(GitoriousConfig["archive_cache_dir"], 
                        "#{@repository.hashed_path}-#{@master_sha}.tar.gz")
      File.expects(:exist?).with(cached_path).returns(true)
      
      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[master], :archive_format => "tar.gz"

      assert_response :success      
      assert_equal cached_path, @response.headers["X-Sendfile"]
      assert_equal "application/x-gzip; charset=utf-8", @response.headers["Content-Type"]
      exp_filename = "#{@repository.owner.to_param}-#{@repository.to_param}-master.tar.gz"
      assert_equal "Content-Disposition: attachment; file=\"#{exp_filename}\"", @response.headers["Content-Disposition"]
    end
    
    should "enqueues a job when the tarball isn't cached" do
      cached_path = File.join(GitoriousConfig["archive_cache_dir"], 
                      "#{@repository.hashed_path}-#{@test_master_sha}.tar.gz")
      work_path = File.join(GitoriousConfig["archive_work_dir"], 
                      "#{@repository.hashed_path}-#{@test_master_sha}.tar.gz")
      File.expects(:exist?).with(cached_path).returns(false)
      File.expects(:exist?).with(work_path).returns(false)
      
      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[test master], :archive_format => "tar.gz"

      assert_response 202 # Accepted
      assert_match(/is currently being generated, try again later/, @response.body)
      assert_equal "text/plain; charset=utf-8", @response.headers["Content-Type"]
      # assert_equal "Content-Disposition: inline; file=\"in_progress.txt\"", @response.headers["Content-Disposition"]
      
      msg = ActiveMessaging::Gateway.connection.find_message("/queue/GitoriousRepositoryArchiving", 
                                                              /#{@test_master_sha}/)
      assert_not_nil msg
      msg_hash = ActiveSupport::JSON.decode(msg.body)
      assert_equal @repository.full_repository_path, msg_hash["full_repository_path"]
      assert_equal cached_path, msg_hash["output_path"]
      assert_equal @test_master_sha, msg_hash["commit_sha"]
      assert_equal "tar.gz", msg_hash["format"]
    end
    
    should "enqueues a job when the tarball isn't cached, unless work has already begun" do
      cached_path = File.join(GitoriousConfig["archive_cache_dir"], 
                      "#{@repository.hashed_path}-#{@master_sha}.tar.gz")
      work_path = File.join(GitoriousConfig["archive_work_dir"], 
                      "#{@repository.hashed_path}-#{@master_sha}.tar.gz")
      File.expects(:exist?).with(cached_path).returns(false)
      File.expects(:exist?).with(work_path).returns(true)
      
      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[master], :archive_format => "tar.gz"

      assert_response 202 # Accepted
      msg = ActiveMessaging::Gateway.connection.find_message("/queue/GitoriousRepositoryArchiving", 
                                                              /#{@master_sha}/)
      assert_nil msg
    end
  end

end
