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
require "repository_creator"

class RepositoryCreatorTest < ActiveSupport::TestCase
  should "create repository" do
    @user = users(:moe)
    @project = @user.projects.first

    assert_difference("Repository.count") do
      outcome = RepositoryCreator.run(params)

      assert outcome.success?, outcome.errors.inspect
      assert_equal "my_repo", outcome.result.name
      assert_equal @project.owner, outcome.result.owner
      assert_equal @user, outcome.result.user
      assert_equal Repository::KIND_PROJECT_REPO, outcome.result.kind
    end
  end

  should "create repository owned by group" do
    @project = projects(:thunderbird)
    @user = users(:mike)
    group = groups(:team_thunderbird)

    assert_difference("Repository.count") do
      outcome = RepositoryCreator.run(params)

      assert outcome.success?, outcome.errors.inspect
      assert_equal group, outcome.result.owner
    end
  end

  should "reject creating repository in project where user has no admin rights" do
    @project = projects(:thunderbird)
    @user = users(:moe)

    outcome = RepositoryCreator.run(params)

    refute outcome.success?
    assert_equal({ "owner" => :authorization }, outcome.errors.symbolic)
  end

  should "enable merge requests by default" do
    outcome = RepositoryCreator.run(params)

    assert outcome.result.merge_requests_enabled?
  end

  should "opt-out of merge requests" do
    outcome = RepositoryCreator.run(params("merge_requests_enabled" => "0"))

    refute outcome.result.merge_requests_enabled?
  end

  should "create public repository by default" do
    Gitorious.stubs(:private_repositories?).returns(true)

    outcome = RepositoryCreator.run(params)
    assert can_read?(nil, outcome.result)
  end

  should "create private project" do
    Gitorious.stubs(:private_repositories?).returns(true)

    outcome = RepositoryCreator.run(params(:private_repository => "1"))
    refute can_read?(nil, outcome.result)
    assert can_read?(@user, outcome.result)
  end

  should "create public project" do
    Gitorious.stubs(:private_repositories?).returns(true)

    outcome = RepositoryCreator.run(params(:private_repository => "0"))
    assert outcome.success?, outcome.errors.inspect
    assert_equal 0, outcome.result.content_memberships.count
  end

  should "not create private project if not enabled" do
    Gitorious.stubs(:private_repositories?).returns(false)

    outcome = RepositoryCreator.run(params(:private_repository => "1"))
    assert_equal 0, outcome.result.content_memberships.count
  end

  def params(hash = {})
    @user ||= users(:moe)
    @project ||= @user.projects.first

    { "name" => "my_repo",
      "project" => @project,
      "user" => @user,
      "description" => "A fine repository"
    }.merge(hash)
  end
end
