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
require 'gitorious/ref_name_resolver'

module CommitAction
  def commit_action
    branch = params[:branch]
    return redirect_to_head_candidate if branch.blank?

    @git = @repository.git
    @ref, _ = branch_and_path(branch, @git)
    head = get_head(@ref)

    return handle_unknown_ref(@ref, @git, ref_type) unless head
    return redirect_to_full_sha(head) unless full_sha?(branch)

    render_index = build_render_index(head)

    if stale_conditional?(head.commit.id, head.commit.committed_date.utc)
      yield(@ref, head, render_index)
    end
  end

  private

  def build_render_index(head)
    lambda do |opts = {}|
      respond_to do |format|
        format.html do
          render(:action => :index, :locals => {
            :repository => RepositoryPresenter.new(@repository),
            :atom_auto_discovery_url => atom_url(head),
            :atom_auto_discovery_title => atom_title}.merge(opts))
        end
      end
    end
  end

  def atom_url(head)
    ref_name = Gitorious::RefNameResolver.sha_to_ref_name(@git, head.commit.id)
    project_repository_formatted_commits_feed_path(@project, @repository, ref_name, :format => :atom)
  end

  def atom_title
    "#{@repository.title} ATOM feed"
  end

  def ref_type
    raise "#{self} does not overwrite ref_type!"
  end

  def full_sha?(sha)
    sha.size >= 40
  end

  def redirect_to_head_candidate
    redirect_to_ref(@repository.head_candidate.name, ref_type)
  end

  def redirect_to_full_sha(head)
    redirect_to_ref(head.commit.id, ref_type, :status => 307)
  end
end
