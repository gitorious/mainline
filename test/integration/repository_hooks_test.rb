# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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
require "fileutils"

class RepositoryHooksTest < ActiveSupport::TestCase

  def assert_hooks(repos_path, repo_path)
    %w[pre-receive post-receive update post-update messaging.rb].each do |hook|
      assert_equal "../../.hooks/#{hook}", File.readlink("#{repo_path}/hooks/#{hook}")
    end
  end

  def create_hook(path)
    FileUtils.touch(path)
    File.chmod(755, path)
  end

  should "symlink hooks" do
    Dir.mktmpdir do |dir|
      repos_path = "#{dir}/repos"
      FileUtils.mkdir(repos_path)
      RepositoryRoot.default_base_path = repos_path
      repo_path = "#{repos_path}/repo.git"
      FileUtils.mkdir(repo_path)

      RepositoryHooks.create(Pathname(repo_path))
      assert_hooks(repos_path, repo_path)

      # do it again and ensure it's idempotent
      RepositoryHooks.create(Pathname(repo_path))
      assert_hooks(repos_path, repo_path)
    end
  end

  should "returns path to the executable custom hook" do
    Dir.mktmpdir do |dir|
      global_hooks_path = "#{dir}/global-hooks"
      FileUtils.mkdir(global_hooks_path)

      repo_path = "#{dir}/repo.git"
      FileUtils.mkdir_p("#{repo_path}/hooks")

      # each additional hook added below shadows the previous ones

      assert_equal nil, RepositoryHooks.custom_hook_path(repo_path, "pre-receive", global_hooks_path)

      # 1. custom global hook at arbitrary path, set in config file

      config_hook_path = "#{dir}/hook"
      create_hook(config_hook_path)

      Gitorious::Configuration.override("custom_pre_receive_hook" => config_hook_path) do |conf|
        assert_equal config_hook_path, RepositoryHooks.custom_hook_path(repo_path, "pre-receive", global_hooks_path)
      end

      # 2. custom global hook in global hooks dir (Rails.root/data/hooks)

      global_hook_path = "#{global_hooks_path}/custom-pre-receive"
      create_hook(global_hook_path)

      Gitorious::Configuration.override("custom_pre_receive_hook" => config_hook_path) do |conf|
        assert_equal global_hook_path, RepositoryHooks.custom_hook_path(repo_path, "pre-receive", global_hooks_path)
      end

      # 3. custom local hook in repo_path/hooks

      local_hook_path = "#{repo_path}/hooks/custom-pre-receive"
      create_hook(local_hook_path)

      Gitorious::Configuration.override("custom_pre_receive_hook" => config_hook_path) do |conf|
        assert_equal local_hook_path, RepositoryHooks.custom_hook_path(repo_path, "pre-receive", global_hooks_path)
      end
    end
  end

end
