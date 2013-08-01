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
require "create_project_repository"

class App < MessageHub
  def admin?(actor, subject); true; end
end

class CreateProjectRepositoryTest < ActiveSupport::TestCase
  def setup
    @app = App.new
    @user = users(:moe)
    @project = @user.projects.first
  end

  should "fail without user" do
    outcome = CreateProjectRepository.new(@app, @project, nil).execute(params)

    refute outcome.success?, outcome.to_s
    assert outcome.pre_condition_failed?, outcome.to_s
  end

  should "reject creating repository in project where user has no admin rights" do
    @app.stubs(:admin?).returns(false)
    outcome = CreateProjectRepository.new(@app, @project, @user).execute(params)

    refute outcome.success?, outcome.to_s
    assert outcome.pre_condition_failed?, outcome.to_s
  end

  should "limit rate of repository creation" do
    count = Repository.count
    use_case = CreateProjectRepository.new(@app, @project, @user)
    outcome = use_case.execute(params(:name => "repo1"))
    outcome = use_case.execute(params(:name => "repo2"))
    outcome = use_case.execute(params(:name => "repo3"))
    outcome = use_case.execute(params(:name => "repo4"))
    outcome = use_case.execute(params(:name => "repo5"))
    outcome = use_case.execute(params(:name => "repo6"))

    refute outcome.success?, outcome.to_s
    assert_instance_of RepositoryRateLimiting, outcome.pre_condition_failed.pre_condition
    assert_equal count + 5, Repository.count
  end

  should "create repository" do
    outcome = CreateProjectRepository.new(@app, @project, @user).execute(params)

    assert outcome.success?, outcome.to_s
    assert_equal "my_repo", outcome.result.name
    assert_equal @project.owner, outcome.result.owner
    assert_equal @user, outcome.result.user
    assert_equal Repository::KIND_PROJECT_REPO, outcome.result.kind
  end

  should "fail repository validation" do
    outcome = CreateProjectRepository.new(@app, @project, @user).execute(params(:name => nil))

    refute outcome.success?, outcome.to_s
    refute_nil outcome.failure.errors[:name]
  end

  should "use a sharded hashed path if RepositoryRoot is configured to" do
    RepositoryRoot.stubs(:shard_dirs?).returns(true)
    outcome = CreateProjectRepository.new(@app, @project, @user).execute(params)
    repository = outcome.result

    refute_nil repository.hashed_path
    assert_equal 3, repository.hashed_path.split("/").length
    assert_match /[a-z0-9\/]{42}/, repository.hashed_path
  end

  def params(hash = {})
    { :name => "my_repo",
      :description => "A fine repository"
    }.merge(hash)
  end
end
