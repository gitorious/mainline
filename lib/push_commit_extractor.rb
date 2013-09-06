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
class PushCommitExtractor
  def initialize(repository_path, spec)
    @spec = spec
    @rugged_repo = Rugged::Repository.new(repository_path)
  end

  def existing_refs
    @existing_refs ||= @rugged_repo.refs
  end

  def existing_ref_names
    existing_refs.map(&:name).map {|r| r.split("/").last}
  end

  def new_commits
    @new_commits ||= fetch_new_commits
  end

  def fetch_new_commits
    walker = Rugged::Walker.new(@rugged_repo)
    walker.push(@spec.to_sha.sha)
    candidates = existing_refs

    heads = candidates.reject do |head|
      head.name.split("/").last == @spec.ref_name || /^refs\/tags/.match(head.name)
    end

    if @spec.action_create?
      heads.each { |head| walker.hide(head.target) }
    else
      walker.hide(@spec.from_sha.sha)
    end

    new_shas = walker.map {|c| c}
    walker.reset
    return new_shas
  end

  def newest_known_commit
    if new_commits.empty? || new_commits.last.parents.empty?
      @rugged_repo.lookup(@spec.to_sha.sha)
    else
      new_commits.last.parents.first
    end
  end
end
