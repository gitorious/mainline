# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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

class Api::GraphsControllerTest < ActionController::TestCase
  def setup
    @repo = repositories(:johans)
    @project = @repo.project
    @cache_key = "commit-graph-#{@project.slug}/#{@repo.name}/"
    @cache_key_all = "commit-graph-#{@project.slug}/#{@repo.name}/--all"
    Rails.cache.delete(@cache_key)
    Rails.cache.delete(@cache_key_all)
    cache = Rails.cache

    def cache.fetch(*args, &block)
      yield
    end
  end

  def expect_cache(key)
    Rails.cache.expects(:fetch).with(key, :expires_in => 1.hour).returns("")
  end

  def mock_shell
    shell = mock
    @controller.expects(:git_shell).returns(shell)
    shell.stubs(:graph_log)
  end

  context "Graphing the log" do
    should "render JSON" do
      path = @repo.full_repository_path
      mock_shell.with(path, ["--decorate=full", "-100", ""], nil).returns("")
      get :show, params
      assert_response :success
    end

    should "cache regular log lookup" do
      expect_cache(@cache_key)
      get :show, params
      assert_response :success
    end

    should "cache log --all" do
      expect_cache(@cache_key_all)
      get :show, params(:type => "all")
      assert_response :success
    end

    should "render JSON formatted message object on timeout" do
      mock_shell.raises(Gitorious::GitShell::GitTimeout.new)
      get :show, params

      assert_response 503
      assert_equal JSON.parse(@response.body), { "message" => "Git timeout" }
    end

    should "render graph for specific sha-ish" do
      mock_shell.with(@repo.full_repository_path, ["--decorate=full", "-100", ""], "refactor").returns("")
      get :show, params(:branch => "refactor")

      assert_response :success
    end

    should "render graph --all for specific sha-ish" do
      mock_shell.with(@repo.full_repository_path, ["--decorate=full", "-100", "--all"], "refactor").returns("")
      get :show, params(:branch => "refactor", :type => "all")
      assert_response :success
    end

    should "treat type != all as blank" do
      mock_shell.with(@repo.full_repository_path, ["--decorate=full", "-100", ""], "branch2").returns("")
      get :show, params(:branch => "branch2", :type => "sumptn")
      assert_response :success
    end

    should "handle branch with slash in it" do
      mock_shell.with(@repo.full_repository_path, ["--decorate=full", "-100", ""], "some/such").returns("")
      get :show, params(:branch => "some%2Fsuch")
      assert_response :success
    end
  end

  context "With private project" do
    setup do
      enable_private_repositories
    end

    should "disallow unauthorized user to graph branch" do
      get :show, params
      assert_response 403
    end

    should "allow authorized user to graph branch" do
      mock_shell.with(@repo.full_repository_path, ["--decorate=full", "-100", ""], nil).returns("")
      login_as :johan
      get :show, params
      assert_response 200
    end
  end

  context "With private repository" do
    setup do
      enable_private_repositories(@repo)
    end

    should "disallow unauthorized user to graph branch" do
      get :show, params
      assert_response 403
    end

    should "allow authorized user to graph branch" do
      mock_shell.with(@repo.full_repository_path, ["--decorate=full", "-100", ""], nil).returns("")
      login_as :johan
      get :show, params
      assert_response 200
    end
  end

  def params(data = {})
    { :project_id => @project.to_param,
      :repository_id => @repo.to_param,
      :format => "json" }.merge(data)
  end
end
