# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

require 'grit'

module SampleRepoHelpers
  def sample_repo_path(name = 'sample_repo')
    tmp_dir = Dir::Tmpname.create("repos") {}
    sample_repos << tmp_dir
    FileUtils.cp_r("#{Rails.root}/test/fixtures/#{name}", tmp_dir)
    tmp_dir
  end

  def sample_rugged_repo(name = 'sample_repo')
    Rugged::Repository.new(sample_repo_path(name))
  end

  def sample_repo(name = 'sample_repo')
    sample_repo_for_path(sample_repo_path(name))
  end

  def sample_repo_for_path(path)
    Grit::Repo.new(path, :is_bare => true)
  end

  def repository_with_working_git(name = 'sample_repo', repository = Repository.new)
    path = sample_repo_path(name)
    git = sample_repo_for_path(path)
    repository.stubs(:git => git, :full_repository_path => path)
    repository
  end

  def cleanup_sample_repos
    sample_repos.each { |f| FileUtils.rm_rf(f) }
    sample_repos.clear
  end

  def sample_repos
    @sample_repos ||= []
  end

  def self.included(context)
    context.teardown { cleanup_sample_repos } if context.respond_to?(:teardown)
    context.after { cleanup_sample_repos } if context.respond_to?(:after)
  end
end

