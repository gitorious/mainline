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

require "test_helper"

class MergeRequestsShowTest < ActionDispatch::IntegrationTest
  include CapybaraTestCase
  js_test

  def login_as(name)
    user = users(name)
    fill_in 'Email or login', :with => user.email
    fill_in 'Password', :with => 'test'
    click_button 'Log in'
  end

  def visit_show_page
    url = project_repository_merge_request_path(
      @project, @target_repository, @merge_request
    )
    visit url
  end

  TestCommit = Struct.new(:id, :name, :message) do
    def id_abbrev
      id.to_s[0..6]
    end
    def committer
      name
    end
    def committed_date
      1.year.ago
    end
    def short_message
      message
    end
  end

  def setup
    @project = projects(:johans)
    @project.update_attribute(:merge_requests_need_signoff, false)
    MergeRequestStatus.create_defaults_for_project(@project)
    grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(grit)
    @source_repository = repositories(:johans2)
    @target_repository = repositories(:johans)
    @merge_request = merge_requests(:moes_to_johans_open)
    @merge_request.stubs(:commit_merged?).returns(true)
    version = @merge_request.create_new_version('ff')
    MergeRequestVersion.any_instance.stubs(:affected_commits).returns([])
    @merge_request.versions << version
    version.stubs(:merge_request).returns(@merge_request)

    commit_stub = TestCommit.new("fff", "This is great")
    MergeRequest.any_instance.stubs(:commits_for_selection).returns([commit_stub])

    assert_not_nil @merge_request.versions.last
  end

  should 'show merge request information' do
    visit_show_page

    assert page.has_content?(@merge_request.summary)
    assert page.has_content?(@merge_request.proposal)
  end

  should 'display watch/unwatch for signed in user' do
    visit new_sessions_path
    login_as :johan
    visit_show_page
    click_on 'Watch'
    assert page.has_content?('Unwatch')
    click_on 'Unwatch'
    assert page.has_content?('Watch')
  end
end
