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

class TreesControllerTest < ActionController::TestCase
  
  should_render_in_site_specific_context :except => [:archive]

  should_enforce_ssl_for(:get, :archive)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :show)

  context "routing" do
    should_eventually "recognize a single glob with a format" do
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

    should_eventually "recognize multiple globs with a format" do
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
    @grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(@grit)
  end

  context "#index" do
    should "redirect to the master head, if not :id given" do
      get :index, :project_id => @project.slug, :repository_id => @repository.name
      assert_redirected_to(project_repository_tree_path(@project, @repository, ["master"]))
    end
  end

  context "#show" do
    should "GET successfully" do
      get :show, :project_id => @project.to_param, 
        :repository_id => @repository.to_param, :branch_and_path => ["master", "lib", "grit"]

      assert_response :success
      assert_equal @repository.git.tree("81a18c36ebe04e406ab84ccc911d79e65e14d1c0"), assigns(:tree)
      assert_equal "master", assigns(:ref)
      assert_equal ["lib", "grit"], assigns(:path)
    end

    should "redirect to HEAD if provided sha was not found (backwards compat)" do
      get :show, :project_id => @project.slug, 
        :repository_id => @repository.name, :branch_and_path => ["a"*40, "foo"]

      assert_redirected_to(project_repository_tree_path(@project, @repository, ["HEAD", "foo"]))
    end

    should "set a pseudo-head if the tree ref is a sha" do
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

    should "cache the tree" do
      get :show, :project_id => @project.to_param, :repository_id => @repository.to_param, 
            :branch_and_path => ["test", "master", "lib"]

      assert_response :success
      assert_equal "max-age=30, private", @response.headers['Cache-Control']
    end

    should "redirect to the tree index with a msg if the tree SHA1 was not found" do
      @grit.expects(:commit).with("master").returns(nil)
      get :show, :project_id => @project.to_param, :repository_id => @repository.to_param, 
            :branch_and_path => ["master", "lib"]
      assert_response :redirect
      assert_match(/no such tree sha/i, flash[:error])
    end
  end

  context "Branch names containing a # character" do
    should "show branches with a # in them with great success" do
      git_repo = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
      @repository.git.expects(:commit).with("ticket-#42") \
        .returns(git_repo.commit("master"))
      get :show, :project_id => @project.to_param, :repository_id => @repository.to_param,
        :branch_and_path => ["ticket-%2342"]
      assert_response :success
      assert_equal "ticket-#42", assigns(:ref)
    end

    should "urlencode # in branch names" do
      Repository.any_instance.expects(:head_candidate_name).returns("ticket-#42")
      get :index, :project_id => @project.to_param, :repository_id => @repository.to_param
      assert_response :redirect
      assert_redirected_to project_repository_tree_path(@project, @repository, ["ticket-#42"])
    end
  end

  context "Archive downloads" do
    setup do
      @master_sha = "ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a"
      @test_master_sha = "2d3acf90f35989df8f262dc50beadc4ee3ae1560"
    end

    should "return the correct for an existing cached tarball" do
      cached_path = File.join(GitoriousConfig["archive_cache_dir"], 
                        "#{@repository.hashed_path.gsub(/\//, '-')}-#{@master_sha}.tar.gz")
      File.expects(:exist?).with(cached_path).returns(true)

      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[master], :archive_format => "tar.gz"

      assert_response :success      
      assert_equal cached_path, @response.headers["X-Sendfile"]
      assert_equal "application/x-gzip; charset=utf-8", @response.headers["Content-Type"]
      exp_filename = "#{@repository.project.to_param}-#{@repository.to_param}-master.tar.gz"
      assert_equal "Content-Disposition: attachment; filename=\"#{exp_filename}\"", @response.headers["Content-Disposition"]
    end

    should "enqueue a job when the tarball is not cached" do
      cached_path = File.join(GitoriousConfig["archive_cache_dir"], 
                      "#{@repository.hashed_path.gsub(/\//, '-')}-#{@test_master_sha}.tar.gz")
      work_path = File.join(GitoriousConfig["archive_work_dir"], 
                      "#{@repository.hashed_path.gsub(/\//, '-')}-#{@test_master_sha}.tar.gz")
      File.expects(:exist?).with(cached_path).returns(false)
      File.expects(:exist?).with(work_path).returns(false)

      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[test master], :archive_format => "tar.gz"

      assert_response 202 # Accepted
      assert_match(/is currently being generated, try again later/, @response.body)
      assert_equal "text/plain; charset=utf-8", @response.headers["Content-Type"]

      assert_published("/queue/GitoriousRepositoryArchiving", {
                         "full_repository_path" => @repository.full_repository_path,
                         "output_path" => cached_path,
                         "format" => "tar.gz"
                       })
    end

    should "not enqueue a job when work has already begun" do
      cached_path = File.join(GitoriousConfig["archive_cache_dir"], 
                      "#{@repository.hashed_path.gsub(/\//, '-')}-#{@master_sha}.tar.gz")
      work_path = File.join(GitoriousConfig["archive_work_dir"], 
                      "#{@repository.hashed_path.gsub(/\//, '-')}-#{@master_sha}.tar.gz")
      File.expects(:exist?).with(cached_path).returns(false)
      File.expects(:exist?).with(work_path).returns(true)

      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[master], :archive_format => "tar.gz"

      assert_response 202 # Accepted

      messages = Gitorious::Messaging::TestAdapter.messages_on("/queue/GitoriousRepositoryArchiving")
      assert_nil messages.find { |m| m["comit_sha"] == @master_sha }
    end

    should "redirect to the first tree when an invalid ref is requested" do
      get :archive, :project_id => @project.slug, :repository_id => @repository.name, 
        :branch => %w[foo], :archive_format => "tar.gz"

      assert_response :redirect
      assert_redirected_to project_repository_tree_path(@project, @repository, 'HEAD')
    end
  end
end
