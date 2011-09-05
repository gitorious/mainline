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

class CommitsControllerTest < ActionController::TestCase

  should_enforce_ssl_for(:get, :feed)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :show)

  context "showing a single commit" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first
      @repository.update_attribute(:ready, true)

      Repository.any_instance.stubs(:full_repository_path).returns(grit_test_repo("dot_git"))
      @grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
      Repository.any_instance.stubs(:git).returns(@grit)
      @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
    end

    should "get the correct project and repository" do
      get :show, {:project_id => @project.to_param,
          :repository_id => @repository.to_param, :id => @sha}
      assert_equal @project, assigns(:project)
      assert_equal @repository, assigns(:repository)
    end

    should "get the commit data" do
      get :show, {:project_id => @project.slug,
          :repository_id => @repository.name, :id => @sha}
      assert_response :success
      assert_equal @repository.git, assigns(:git)
      assert_equal @repository.git.commit(@sha), assigns(:commit)
      assert_not_nil assigns(:diffs)
    end

    should "default to 'inline' diffmode" do
      get :show, {:project_id => @project.slug,
          :repository_id => @repository.name, :id => @sha}
      assert_equal "inline", assigns(:diffmode)
    end

    should "set sidebyside diffmode" do
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

    should "redirect to the commit log with a msg if the SHA1 was not found" do
      @grit.expects(:commit).with("123").returns(nil)
      get :show, :project_id => @project.slug,
          :repository_id => @repository.name, :id => "123"
      assert_response :redirect
      assert_match(/no such sha/i, flash[:error])
      assert_redirected_to project_repository_commits_path(@project, @repository)
    end

    should "have a different last-modified if there is a comment" do
      Comment.create!({
          :user => users(:johan),
          :body => "foo",
          :sha1 => @sha,
          :target => @repository,
          :project => @repository.project,
      })
      get :show, :project_id => @project.slug,
          :repository_id => @repository.name, :id => @sha
      assert_response :success
      assert_not_equal "Fri, 18 Apr 2008 23:26:07 GMT", @response.headers["Last-Modified"]
    end
  end

  context "Routing" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.first
      @repository.update_attribute(:ready, true)
      @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
      @weird_id = '!"#$%&\'()+,-.0123456789;<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ]_`abcdefghijklmnopqrstuvwxyz{|}'
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

    should "route user-namespaced commits index, with dots in the username" do
      assert_recognizes({
        :controller => "commits",
        :action => "show",
        :user_id => "mc.hammer",
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
      }, {:path => "/~mc.hammer/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}", :method => :get})
      assert_generates("/~mc.hammer/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}", {
        :controller => "commits",
        :action => "show",
        :user_id => "mc.hammer",
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
      })
    end

    should "route tags with dots in the id" do
      assert_recognizes({
        :controller => "commits",
        :action => "show",
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => "v0.7.0",
      }, {:path => "/#{@project.to_param}/#{@repository.to_param}/commit/v0.7.0", :method => :get})
      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/v0.7.0", {
        :controller => "commits",
        :action => "show",
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => "v0.7.0",
      })
    end

    should "route branches with weird characters in the id" do
      assert_recognizes({
        :controller => "commits",
        :action => "show",
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @weird_id,
      }, {:path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{@weird_id}", :method => :get})
      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/#{URI.escape(@weird_id, ActionController::Routing::Segment::UNSAFE_PCHAR)}", {
        :controller => "commits",
        :action => "show",
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @weird_id,
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
      }, {
        :path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}",
        :method => :get
      }, {
        :format => "diff",
      })
      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}", {
        :controller => "commits",
        :action => "show",
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
        :format => "diff"
      }, {}, {
        :format => "diff",
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
      }, {
        :path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}",
        :method => :get
      }, {
        :format => "patch",
      })
      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}", {
        :controller => "commits",
        :action => "show",
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
        :format => "patch"
      }, {}, {
        :format => "patch",
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
      @git = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
      Repository.any_instance.stubs(:git).returns(@git)
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

      should "deal gracefully if HEAD file refers to a non-existent ref" do
        @git.expects(:get_head).with("master").returns(nil)
        @git.expects(:commit).with("master").returns(nil)

        get(:index, {
              :project_id => @project.slug,
              :repository_id => @repository.name,
              :page => nil,
              :branch => ["master"]
            })

        assert_response :redirect
        assert_match(/not a valid ref/, flash[:error])
      end

      should "suggest looking at master when hitting non-existent ref" do
        @git.expects(:get_head).with("2").returns(nil)
        @git.expects(:commit).with("2").returns(nil)

        get(:index, {
              :project_id => @project.slug,
              :repository_id => @repository.name,
              :page => nil,
              :branch => ["2"]
            })

        assert_response :redirect
        assert_redirected_to project_repository_commits_in_ref_path(@project,
                              @repository, "master")
        assert_match(/trying master instead/, flash[:error])
      end

      should "suggest looking at master when hitting non-existent commit" do
        @git.expects(:get_head).with("2").returns(nil)
        @git.expects(:commit).with("2").raises(Errno::EISDIR, "Is a directory")

        get(:index, {
              :project_id => @project.slug,
              :repository_id => @repository.name,
              :page => nil,
              :branch => ["2"]
            })

        assert_response :redirect
        assert_redirected_to project_repository_commits_in_ref_path(@project,
                              @repository, "master")
        assert_match(/trying master instead/, flash[:error])
      end

      should "have a proper id in the atom feed" do
        #(repo, id, parents, tree, author, authored_date, committer, committed_date, message)
        commit = Grit::Commit.new(mock("repo"), "mycommitid", [], stub_everything("tree"),
                      stub_everything("author"), Time.now,
                      stub_everything("comitter"), Time.now,
                      "my commit message".split(" "))
        @repository.git.expects(:commits).twice.returns([commit])

        get :feed, {:project_id => @project.slug,
          :repository_id => @repository.name, :id => "master", :format => "atom"}
        assert @response.body.include?(%Q{<id>tag:test.host,2005:Grit::Commit/mycommitid</id>})
      end

      should "not explode when there is no commits" do
        @repository.git.expects(:commits).returns([])
        get :feed, {:project_id => @project.slug,
          :repository_id => @repository.name, :id => "master", :format => "atom"}
        assert_response :success
        assert_select "feed title", /#{@repository.gitdir}/
      end

      should "show branches with a # in them with great success" do
        git_repo = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
        @repository.git.expects(:commit).with("ticket-#42") \
          .returns(git_repo.commit("master"))
        get :index, :project_id => @project.to_param, :repository_id => @repository.to_param,
          :branch => ["ticket-%2342"]
        assert_response :success
        assert_equal "ticket-#42", assigns(:ref)
      end
    end
  end

  context "paginating commits" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.first
      @repository.update_attribute(:ready, true)
      Project.stubs(:find_by_slug!).with(@project.slug).returns(@project)
      Repository.stubs(:find_by_name_and_project_id!) \
        .with(@repository.name, @project.id).returns(@repository)
      Repository.any_instance.stubs(:full_repository_path).returns(grit_test_repo("dot_git"))
      @git = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
      Repository.any_instance.stubs(:git).returns(@git)

      @params = {
        :project_id => @project.slug,
        :repository_id => @repository.name,
        :branch => ["master"]
      }
    end

    context "commits pagination" do
      should_scope_pagination_to(:index, nil, "commits", :delete_all => false)
    end
  end
end
