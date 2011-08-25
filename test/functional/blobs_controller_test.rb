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

class BlobsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context

  should_enforce_ssl_for(:get, :history)

  context "Blob rendering" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
      @repository.stubs(:full_repository_path).returns(repo_path)

      Project.stubs(:find_by_slug!).with(@project.slug).returns(@project)
      Repository.expects(:find_by_name_and_project_id!) \
          .with(@repository.name, @project.id).returns(@repository)
      @repository.stubs(:has_commits?).returns(true)

      @git = stub_everything("Grit mock")
      @repository.stubs(:git).returns(@git)
      @head = mock("master branch")
      @head.stubs(:name).returns("master")
      @repository.stubs(:head_candidate).returns(@head)
    end
  
    context "#show" do
      should "gets the blob data for the sha provided" do
        blob_mock = mock("blob")
        blob_mock.stubs(:contents).returns([blob_mock]) #meh
        blob_mock.stubs(:data).returns("blob contents")
        blob_mock.stubs(:name).returns("README")
        blob_mock.stubs(:basename).returns("README")
        blob_mock.stubs(:mime_type).returns("text/plain")
        blob_mock.stubs(:size).returns(666)
        blob_mock.stubs(:id).returns("a"*40)
        blob_mock.stubs(:binary?).returns(false)
        commit_stub = mock("commit")
        commit_stub.stubs(:id).returns("a"*40)
        commit_stub.stubs(:tree).returns(commit_stub)
        commit_stub.stubs(:committed_date).returns(2.days.ago)
        @git.expects(:commit).returns(commit_stub)
        @git.expects(:tree).returns(blob_mock)
        @git.stubs(:get_head).returns(stub("head", :name => "master"))
      
        get :show, {:project_id => @project.slug, 
            :repository_id => @repository.name, :branch_and_path => ["a"*40, "README"]}
      
        assert_response :success
        assert_equal @git, assigns(:git)
        assert_equal blob_mock, assigns(:blob)
      end 
    
      should "redirects to HEAD if provided sha was not found (backwards compat)" do
        @git.expects(:commit).with("a"*40).returns(nil)
        @git.expects(:heads).returns(mock("head", :name => "master"))
        get :show, {:project_id => @project.slug, 
            :repository_id => @repository.name, :branch_and_path => ["a"*40, "foo.rb"]}
      
        assert_redirected_to (project_repository_blob_path(@project, @repository, ["HEAD", "foo.rb"]))
      end

      context "Annotations" do
        setup do
          @git.stubs(:commit).with(SHA).returns(stub(:id => SHA, :id_abbrev => "aaa"))
          @blame = mock
          @blame.stubs(:lines).returns([])
          @git.stubs(:blame).with("lib/foo.c", SHA).returns(@blame)
        end
        
        should "not send session cookies" do
          get :blame, {:project_id => @project.slug, :repository_id => @repository.name,
            :branch_and_path => [SHA, "lib","foo.c"]}
          assert_equal [], @response.headers["Set-Cookie"]
        end

        should "expire soonish with shortened ref" do
          @git.stubs(:commit).with("master").returns(stub(:id => SHA, :id_abbrev => "aaa"))
          @git.stubs(:blame).with("lib/foo.c", "master").returns(@blame)
          get :blame, {:project_id => @project.slug, :repository_id => @repository.name,
            :branch_and_path => ["master", "lib","foo.c"]}
          assert_response :success
          assert_match "max-age=3600", @response.headers["Cache-Control"]
        end
        
        should "never expire with full ref" do
          get :blame, {:project_id => @project.slug, :repository_id => @repository.name,
            :branch_and_path => [SHA, "lib","foo.c"]}
          assert_response :success
          assert_match "max-age=315360000", @response.headers["Cache-Control"]
        end
      end
    end
    
    context "#raw" do
      should "get the blob data from a commit sha and a file name and render it as text/plain" do
        blob_mock = mock("blob")
        blob_mock.stubs(:contents).returns([blob_mock]) #meh
        blob_mock.expects(:data).returns("blabla")
        blob_mock.expects(:size).returns(200.kilobytes)
        blob_mock.expects(:mime_type).returns("text/plain")
        blob_mock.expects(:name).returns("README.doc")
        commit_stub = mock("commit")
        commit_stub.stubs(:id).returns("a"*40)
        commit_stub.stubs(:tree).returns(commit_stub)
        commit_stub.stubs(:committed_date).returns(2.days.ago)
        git_mock = mock("git")
        git_mock.expects(:cat_file).returns("commit")
        @git.stubs(:git).returns(git_mock)
        @git.expects(:commit).returns(commit_stub)
        @git.expects(:tree).returns(blob_mock)
      
        get :raw, {:project_id => @project.slug, 
            :repository_id => @repository.name, :branch_and_path => ["a"*40, "README"]}
      
        assert_response :success
        assert_equal @git, assigns(:git)
        assert_equal blob_mock, assigns(:blob)
        assert_equal "blabla", @response.body
        assert_equal "text/plain", @response.content_type
        assert_equal "max-age=1800, private", @response.headers['Cache-Control']
        assert_equal %[attachment;filename="README.doc"], @response.headers["Content-Disposition"]
      end

      should "get the blob data from a blob sha and render it as text/plain" do
        blob_mock = mock("blob")
        blob_mock.stubs(:contents).returns([blob_mock]) #meh
        blob_mock.expects(:data).returns("blabla")
        blob_mock.expects(:size).returns(200.kilobytes)
        blob_mock.expects(:mime_type).returns("text/plain")
        git_mock = mock("git")
        git_mock.expects(:cat_file).returns("blob")
        @git.stubs(:git).returns(git_mock)
        @git.expects(:blob).returns(blob_mock)

        get :raw, {:project_id => @project.slug,
            :repository_id => @repository.name, :branch_and_path => ["a"*40]}

        assert_response :success
        assert_equal @git, assigns(:git)
        assert_equal blob_mock, assigns(:blob)
        assert_equal "blabla", @response.body
        assert_equal "text/plain", @response.content_type
        assert_equal "max-age=1800, private", @response.headers['Cache-Control']
      end

      should "redirects to HEAD if provided sha was not found (backwards compat)" do
        git_mock = mock("git")
        git_mock.expects(:cat_file).returns("commit")
        @git.stubs(:git).returns(git_mock)
        @git.expects(:commit).with("a"*40).returns(nil)
        get :raw, {:project_id => @project.slug, 
            :repository_id => @repository.name, :branch_and_path => ["a"*40, "foo.rb"]}
      
        assert_redirected_to (project_repository_raw_blob_path(@project, @repository, ["HEAD", "foo.rb"]))
      end
    
      should "redirects if blob is too big" do
        blob_mock = mock("blob")
        blob_mock.stubs(:contents).returns([blob_mock]) #meh
        blob_mock.expects(:size).twice.returns(501.kilobytes)
        commit_stub = mock("commit")
        commit_stub.stubs(:id).returns("a"*40)
        commit_stub.stubs(:tree).returns(commit_stub)
        commit_stub.stubs(:committed_date).returns(2.days.ago)
        git_mock = mock("git")
        git_mock.expects(:cat_file).returns("commit")
        @git.stubs(:git).returns(git_mock)
        @git.expects(:commit).returns(commit_stub)
        @git.expects(:tree).returns(blob_mock)
      
        get :raw, {:project_id => @project.slug, 
            :repository_id => @repository.name, :branch_and_path => ["a"*40, "README"]}
          
        assert_redirected_to (project_repository_path(@project, @repository))
      end
    end
    
    context "#history" do
      setup do
        @repository.stubs(:full_repository_path).returns(grit_test_repo("dot_git"))
        @repository.stubs(:git).returns(Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true))
      end
      
      should "get the history of a single file" do
        get :history, :project_id => @project.to_param, :repository_id => @repository.to_param,
          :branch_and_path => ["master", "README.txt"]
        
        assert_response :success
        assert_equal "master", assigns(:ref)
        assert_equal ["README.txt"], assigns(:path)
        assert_equal 5, assigns(:commits).size
      end

      should "get the history as json" do
        get :history, :project_id => @project.to_param, :repository_id => @repository.to_param,
          :branch_and_path => ["master","README.txt"], :format => "json"
        assert_response :success
        json_body = JSON.parse(@response.body)
        assert_equal 5, json_body.size
      end
    end
  end
end
