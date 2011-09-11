# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

require File.dirname(__FILE__) + '/../../test_helper'

class Api::GraphsControllerTest < ActionController::TestCase
  def expect_cache(key)
    Rails.cache.expects(:fetch).with(key, :expires_in => 1.hour).returns("")
  end

  def mock_shell
    shell = mock
    @controller.expects(:git_shell).returns(shell)
    shell.expects(:graph_log)
  end

  context "Graphing the log" do
    setup do
      @repo = repositories(:johans)
      @project = @repo.project
      @cache_key = "commit-graph-#{@project.slug}/#{@repo.name}/"
      @cache_key_all = "commit-graph-#{@project.slug}/#{@repo.name}/--all"
      Rails.cache.delete(@cache_key)
      Rails.cache.delete(@cache_key_all)
    end

    should "render JSON" do
      mock_shell.with(@repo.full_repository_path, "--decorate=full", "-100", "").returns("")

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repo.name,
        :format => "json"
      }

      assert_response :success
    end

    should "cache regular log lookup" do
      expect_cache(@cache_key)

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repo.name,
        :format => "json"
      }

      assert_response :success
    end

    should "cache log --all" do
      expect_cache(@cache_key_all)

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repo.name,
        :format => "json",
        :type => "all"
      }

      assert_response :success
    end

    should "render an empty JSON array on timeout" do
      mock_shell.raises(Gitorious::GitShell::GitTimeout.new)

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repo.name,
        :format => "json"
      }

      assert_response :success
    end

    should "render graph for specific sha-ish" do
      mock_shell.with(@repo.full_repository_path, "--decorate=full", "-100", "", "refactor").returns("")

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repo.name,
        :branch => "refactor",
        :format => "json"
      }

      assert_response :success
    end

    should "render graph --all for specific sha-ish" do
      mock_shell.with(@repo.full_repository_path, "--decorate=full", "-100", "--all", "refactor").returns("")

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repo.name,
        :branch => "refactor",
        :format => "json",
        :type => "all"
      }

      assert_response :success
    end

    should "treat type != all as blank" do
      mock_shell.with(@repo.full_repository_path, "--decorate=full", "-100", "", "branch2").returns("")

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repo.name,
        :branch => "branch2",
        :format => "json",
        :type => "sumptn"
      }

      assert_response :success
    end

    should "handle branch with slash in it" do
      mock_shell.with(@repo.full_repository_path, "--decorate=full", "-100", "", "some/such").returns("")

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repo.name,
        :branch => "some%2Fsuch",
        :format => "json"
      }

      assert_response :success
    end
  end
end
