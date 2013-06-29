# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class RepositoryConfigurationsControllerTest < ActionController::TestCase
  def setup
    @settings = Gitorious::Configuration.prepend("enable_private_repositories" => false)
    setup_ssl_from_config
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(@grit)
    login_as :johan
  end

  teardown do
    Gitorious::Configuration.prune(@settings)
  end

  context "#writable_by" do
    should "not require login" do
      session[:user_id] = nil
      do_writable_by_get :username => "johan"
      assert_response :success
    end

    should "get projects/1/repositories/3/writable_by?username=johan is true" do
      do_writable_by_get :username => "johan"
      assert_response :success
      assert_equal "true", @response.body
    end

    should "get projects/1/repositories/2/writable_by?username=johan is false" do
      do_writable_by_get :username => "johan", :project_id => projects(:moes).slug,
      :id => projects(:moes).repositories.first.name
      assert_response :success
      assert_equal "false", @response.body
    end

    should "get projects/1/repositories/2/writable_by?username=nonexistinguser is false" do
      do_writable_by_get :username => "nonexistinguser"
      assert_response :success
      assert_equal "false", @response.body
    end

    should "finds the repository in the whole project realm, if the (url) root is a project" do
      # in case someone changes a mainline to be owned by a group
      assert_equal @project, repositories(:johans2).project
      do_writable_by_get :id => repositories(:johans2).to_param
      assert_response :success
    end

    should "scope to the correct project" do
      cmd = CloneRepositoryCommand.new(MessageHub.new, repositories(:moes), users(:johan))
      repo_clone = cmd.execute(cmd.build(CloneRepositoryInput.new(:name => "johansprojectrepos")))

      do_writable_by_get({
          :project_id => projects(:moes).to_param,
          :id => repo_clone.to_param,
        })

      assert_response :success
    end

    should "not require any particular subdomain (if Project belongs_to a site)" do
      project = projects(:johans)
      assert_not_nil project.site
      do_writable_by_get :project_id => project.to_param,
      :id => project.repositories.mainlines.first.to_param
      assert_response :success
    end

    should "not identify a non-merge request git path as a merge request" do
      do_writable_by_get({
          :git_path => "refs/heads/master"})
      assert_response :success
      assert_equal "true", @response.body
    end

    should "identify that a merge request is being pushed to" do
      @merge_request = merge_requests(:mikes_to_johans)
      assert !can_push?(@merge_request.user, @merge_request.target_repository)
      do_writable_by_get({
          :username => @merge_request.user.to_param,
          :project_id => @merge_request.target_repository.project.to_param,
          :id => @merge_request.target_repository.to_param,
          :git_path => "refs/merge-requests/#{@merge_request.to_param}"})
      assert_response :success
      assert_equal "true", @response.body
    end

    should "not allow other users than the owner of a merge request push to a merge request" do
      @merge_request = merge_requests(:mikes_to_johans)
      do_writable_by_get({
          :username => "johan",
          :project_id => @merge_request.target_repository.project.to_param,
          :id => @merge_request.target_repository.to_param,
          :git_path => "refs/merge-requests/#{@merge_request.to_param}"})
      assert_response :success
      assert_equal "false", @response.body
    end

    should "not allow pushes to non-existing merge requests" do
      @merge_request = merge_requests(:mikes_to_johans)
      do_writable_by_get({
          :username => "johan",
          :project_id => @merge_request.target_repository.project.to_param,
          :id => @merge_request.target_repository.to_param,
          :git_path => "refs/merge-requests/42"})
      assert_response :success
      assert_equal "false", @response.body
    end

    should "allow pushing to wiki repositories" do
      project = projects(:johans)
      wiki = project.wiki_repository
      user = users(:johan)
      do_writable_by_get(:id => wiki.to_param)
      assert_response :success
    end
  end

  context "#config" do
    should "not require login" do
      session[:user_id] = nil
      do_config_get
      assert_response :success
    end

    should "get projects/1/repositories/3/config is true" do
      do_config_get
      assert_response :success
      exp = "real_path:#{@repository.real_gitdir}\nforce_pushing_denied:false"
      assert_equal exp, @response.body
    end

    should "expose the wiki repository" do
      wiki = @project.wiki_repository
      assert_not_nil wiki
      do_config_get(:id => wiki.to_param)
      expected = "real_path:#{wiki.real_gitdir}\nforce_pushing_denied:false"
      assert_equal expected, @response.body
    end

    should "not use a session cookie" do
      do_config_get

      assert_nil @response.headers["Set-Cookie"]
    end

    should "send cache friendly headers" do
      do_config_get

      assert_equal "public, max-age=600", @response.headers["Cache-Control"]
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
      @repository = @project.repositories.first
      Repository.any_instance.stubs(:has_commits?).returns(true)
    end

    should "not disallow writable_by? action" do
      do_writable_by_get :username => "mike"
      assert_response :success
      assert_equal "false", @response.body
    end

    should "allow owner to write to repo" do
      do_writable_by_get :username => "johan"
      assert_response :success
      assert_equal "true", @response.body
    end

    should "disallow unauthorized user to access repository configuration" do
      do_config_get(:username => "mike")
      assert_response 403
    end

    should "disallow anonymous user to access repository configuration" do
      do_config_get
      assert_response 403
    end

    should "allow authorized user to access repository configuration" do
      do_config_get(:username => "johan")
      assert_response 200
    end
  end

  context "With private repositories" do
    setup do
      enable_private_repositories(@repo)
      @repository = @project.repositories.first
      Repository.any_instance.stubs(:has_commits?).returns(true)
    end

    teardown do
      user = users(:mike)
      user.is_admin = false
      user.save
    end

    should "not disallow writable_by? action" do
      do_writable_by_get :username => "mike"
      assert_response :success
      assert_equal "false", @response.body
    end

    should "allow owner to write to repo" do
      do_writable_by_get :username => "johan"
      assert_response :success
      assert_equal "true", @response.body
    end

    should "disallow unauthorized user to access repository configuration" do
      do_config_get(:username => "mike")
      assert_response 403
    end

    should "disallow anonymous user to access repository configuration" do
      do_config_get
      assert_response 403
    end

    should "allow authorized user to access repository configuration" do
      do_config_get(:username => "johan")
      assert_response 200
    end
  end

  def do_writable_by_get(options={})
    post(:writable_by, {
        :project_id => @project.slug,
        :id => @repository.name,
        :username => "johan"
      }.merge(options))
  end

  def do_config_get(options={})
    get(:show, {:project_id => @project.slug, :id => @repository.name}.merge(options))
  end
end
