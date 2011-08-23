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
  context "Graphing the log" do
    setup do
      @repository = repositories(:johans)
      @project = @repository.project
      @cache_key = "commit-graph-in-#{@project.slug}/#{@repository.name}"
      Rails.cache.delete(@cache_key)
    end

    should "render JSON" do
      shell = mock
      shell.expects(:graph_log).with(@repository.full_repository_path, "-50").returns("")

      @controller.expects(:git_shell).returns(shell)

      get :show, {:project_id => @project.slug, :repository_id => @repository.name, :format => "json"}
      assert_response :success
    end

    should "be cached" do
      Rails.cache.expects(:fetch).with(@cache_key, :expires_in => 1.hour).returns("")

      get :show, {:project_id => @project.slug, :repository_id => @repository.name, :format => "json"}
      assert_response :success
    end

    should "render an empty JSON array on timeout" do
      shell = mock
      shell.expects(:graph_log).raises(Gitorious::GitShell::GitTimeout.new)

      @controller.expects(:git_shell).returns(shell)

      get :show, {:project_id => @project.slug, :repository_id => @repository.name, :format => "json"}
      assert_response :success
    end

    should "render graph for specific sha-ish" do
      shell = mock
      shell.expects(:graph_log).with(@repository.full_repository_path, "-50", "refactor").returns("")

      @controller.expects(:git_shell).returns(shell)

      get :show, {
        :project_id => @project.slug,
        :repository_id => @repository.name,
        :branch => "refactor",
        :format => "json"
      }

      assert_response :success
    end
  end
end
