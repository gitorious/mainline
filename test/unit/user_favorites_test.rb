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

class DashboardTest < ActiveSupport::TestCase
  setup do
    @user = users(:johan)
    @dashboard = UserFavorites.new(@user)
  end

  should "return watched projects" do
    project = projects(:moes)
    favorite = project.watched_by!(@user)

    assert_include @dashboard.favorites, favorite
  end

  should "return watched repositories" do
    repository = repositories(:moes)
    favorite = repository.watched_by!(@user)

    assert_include @dashboard.favorites, favorite
  end

  should "return repositories of watched projects" do
    project = projects(:moes)
    favorite = project.watched_by!(@user)
    repos = project.repositories.mainlines

    assert_include @dashboard.favorites.map(&:watchable), *repos
  end

  should "return merge requests of watched repositories" do
    merge_request = merge_requests(:moes_to_johans)

    assert_include @dashboard.favorites.map(&:watchable), merge_request
  end

  should "return merge requests of watched projects" do
    user = users(:mike)
    projects(:johans).watched_by!(user)
    merge_request = merge_requests(:moes_to_johans)

    dashboard = Dashboard.new(user)

    assert_include dashboard.favorites.map(&:watchable), merge_request
  end

  should "return projects where user is a collaborator" do
    user = users(:moe)
    groups(:team_thunderbird).add_member(user, Role.member)
    project = projects(:thunderbird)

    dashboard = Dashboard.new(user)

    assert_include dashboard.favorites.map(&:watchable), project
  end

  should "return repositories where users is a committer" do
    user = users(:moe)
    repository = repositories(:johans)
    repository.committerships.create!(committer: user)

    dashboard = Dashboard.new(user)

    assert_include dashboard.favorites.map(&:watchable), repository
  end

  should "not return duplicates" do
    repository = repositories(:johans)
    assert_equal 1, @dashboard.favorites.map(&:watchable).count { |w| w == repository }
  end

  should "return open merge requests" do
    merge_request = merge_requests(:moes_to_johans_open)
    favorite = merge_request.watched_by!(@user)

    assert_include @dashboard.favorites, favorite
  end

  should "not return closed merge requests" do
    merge_request = merge_requests(:moes_to_johans_open)
    merge_request.close
    favorite = merge_request.watched_by!(@user)

    assert_not_include @dashboard.favorites, favorite
  end
end
