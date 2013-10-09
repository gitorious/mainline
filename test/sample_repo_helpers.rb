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

module SampleRepoHelpers
  def sample_repo_path(name)
    tmp_dir = Dir::Tmpname.create("repos") {}
    sample_repos << tmp_dir
    FileUtils.cp_r("#{Rails.root}/test/fixtures/#{name}", tmp_dir)
    tmp_dir
  end

  def sample_repo(name)
    Grit::Repo.new(sample_repo_path(name), :is_bare => true)
  end

  def cleanup_sample_repos
    sample_repos.each { |f| FileUtils.rm_rf(f) }
    sample_repos.clear
  end

  def sample_repos
    @sample_repos ||= []
  end

  def self.included(context)
    context.teardown do
      cleanup_sample_repos
    end
  end
end

