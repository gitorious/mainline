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
    assert_equal "#{Rails.root}/data/hooks", File.readlink("#{repos_path}/.hooks")

    %w[pre-receive post-receive update post-update messaging.rb].each do |hook|
      assert_equal "../../.hooks/#{hook}", File.readlink("#{repo_path}/hooks/#{hook}")
    end
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

end
