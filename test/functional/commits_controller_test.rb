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

require "test_helper"

class CommitsControllerTest < ActionController::TestCase
  context "showing a single commit" do
    setup do
      prepare_project_repo_and_commit
    end

    should "get the correct project and repository" do
      get :show, params
      assert_equal @project, assigns(:project)
      assert_equal @repository, assigns(:repository)
    end

    should "get the commit data" do
      get :show, params
      assert_response :success
      assert_match /added a git directory/, response.body
    end

    should "get it in diff format" do
      get :show, params(:format => "diff")
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal @repository.git.commit(@sha).diffs.map{|d| d.diff}.join("\n"), @response.body
    end

    should "get it in patch format" do
      get :show, params(:format => "patch")
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal @repository.git.commit(@sha).to_patch, @response.body
    end

    should "redirect to the commit log with a msg if the SHA1 was not found" do
      @grit.expects(:commit).with("123").returns(nil)
      get :show, params(:id => "123")
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
      get :show, params
      assert_response :success
      assert_not_equal "Fri, 18 Apr 2008 23:26:07 GMT", @response.headers["Last-Modified"]
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
        get :index, index_params(:page => nil, :branch => "3fa4e130fa18c92e3030d4accb5d3e0cadd40157")
        assert_response :success
        assert_equal @repository.git.commits("3fa4e130fa18c92e3030d4accb5d3e0cadd40157", 30, 0), assigns(:commits)
      end

      should "GETs page 3 successfully" do
        get :index, index_params(:branch => "3fa4e130fa18c92e3030d4accb5d3e0cadd40157", :page => 3)
        assert_response :success
        assert_equal @repository.git.commits("3fa4e130fa18c92e3030d4accb5d3e0cadd40157", 30, 60), assigns(:commits)
      end

      should "GETs the commits successfully" do
        get :index, index_params(:page => nil, :branch => "3fa4e130fa18c92e3030d4accb5d3e0cadd40157")
        assert_response :success
        assert_equal @repository.git, assigns(:git)
        assert_equal @repository.git.commits("3fa4e130fa18c92e3030d4accb5d3e0cadd40157", 30, 0), assigns(:commits)
      end

      should "GET the commits of a namedspaced branch successfully" do
        get :index, index_params(:page => nil, :branch => ["test", "master"])
        sha = @repository.git.get_head("test/master").commit.id
        assert_redirected_to(:branch => sha)
      end

      should "deal gracefully if HEAD file refers to a non-existent ref" do
        @git.expects(:get_head).with("master").returns(nil)
        @git.expects(:commit).with("master").returns(nil)
        get :index, index_params(:page => nil, :branch => ["master"])

        assert_response :redirect
        assert_match(/not a valid ref/, flash[:error])
      end

      should "suggest looking at master when hitting non-existent ref" do
        @git.expects(:get_head).with("2").returns(nil)
        @git.expects(:commit).with("2").returns(nil)
        get :index, index_params(:page => nil, :branch => ["2"])

        assert_response :redirect
        assert_redirected_to project_repository_commits_in_ref_path(@project,
                              @repository, "master")
        assert_match(/trying master instead/, flash[:error])
      end

      should "suggest looking at master when hitting non-existent commit" do
        @git.expects(:get_head).with("2").returns(nil)
        @git.expects(:commit).with("2").raises(Errno::EISDIR, "Is a directory")
        get :index, index_params(:page => nil, :branch => ["2"])

        assert_response :redirect
        assert_redirected_to project_repository_commits_in_ref_path(@project,
                              @repository, "master")
        assert_match(/trying master instead/, flash[:error])
      end

      should "have a proper id in the atom feed" do
        commit = Grit::Commit.new(mock("repo"), "mycommitid", [], stub_everything("tree"),
                      stub_everything("author"), Time.now,
                      stub_everything("comitter"), Time.now,
                      "my commit message".split(" "))

        @repository.git.stubs(:commits).with("master", 1).returns([commit])
        @repository.git.stubs(:commits).with("master", 49, 1).returns([])

        get :feed, params(:id => "master", :format => "atom")
        assert @response.body.include?(%Q{<id>tag:test.host,2005:Grit::Commit/mycommitid</id>})
      end

      should "not explode when there is no commits" do
        @repository.git.expects(:commits).returns([])
        get :feed, params(:id => "master", :format => "atom")
        assert_response :success
        assert_select "feed title", /#{@repository.gitdir}/
      end

      should "show branches with a # in them with great success" do
        git_repo = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
        @repository.git.expects(:commit).with("ticket-#42") \
          .returns(git_repo.commit("master"))
        get :index, index_params(:branch => ["ticket-%2342"])
        assert_redirected_to :branch => git_repo.commit("master")
      end
    end
  end

  context "With private projects" do
    setup do
      prepare_project_repo_and_commit
      enable_private_repositories
    end

    should "disallow unauthorized access to commits" do
      get :index, index_params(:page => nil, :branch => ["master"])
      assert_response 403
    end

    should "allow authorized access to commits too" do
      login_as :johan
      get :index, index_params(:page => nil, :branch => "3fa4e130fa18c92e3030d4accb5d3e0cadd40157")
      assert_response 200
    end

    should "disallow unauthorized access to show commit" do
      get :show, params
      assert_response 403
    end

    should "allow authorized access to show commit" do
      login_as :johan
      get :show, params
      assert_response 200
    end

    should "disallow unauthorized access to view feed" do
      get :feed, params(:id => "master", :format => "atom")
      assert_response 403
    end

    should "allow authorized access to view feed" do
      login_as :johan
      get :feed, params(:id => "master", :format => "atom")
      assert_response 200
    end
  end

  context "With private repositories" do
    setup do
      prepare_project_repo_and_commit
      enable_private_repositories(@repository)
    end

    should "disallow unauthorized access to commits" do
      get :index, index_params(:page => nil, :branch => ["master"])
      assert_response 403
    end

    should "allow authorized access to commits" do
      login_as :johan
      get :index, index_params(:page => nil, :branch => "3fa4e130fa18c92e3030d4accb5d3e0cadd40157")
      assert_response 200
    end

    should "disallow unauthorized access to show commit" do
      get :show, params
      assert_response 403
    end

    should "allow authorized access to show commit" do
      login_as :johan
      get :show, params
      assert_response 200
    end

    should "disallow unauthorized access to view feed" do
      get :feed, params(:id => "master", :format => "atom")
      assert_response 403
    end

    should "allow authorized access to view feed" do
      login_as :johan
      get :feed, params(:id => "master", :format => "atom")
      assert_response 200
    end
  end

  private
  def params(additional = {})
    { :project_id => @project.slug,
      :repository_id => @repository.name,
      :id => @sha }.merge(additional)
  end

  def index_params(additional = {})
    { :project_id => @project.slug,
      :repository_id => @repository.name }.merge(additional)
  end

  def prepare_project_repo_and_commit
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @repository.update_attribute(:ready, true)

    Repository.any_instance.stubs(:full_repository_path).returns(grit_test_repo("dot_git"))
    @grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(@grit)
    @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
  end
end
