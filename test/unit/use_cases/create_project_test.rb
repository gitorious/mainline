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

class CreateProjectTest < ActiveSupport::TestCase
  should "create project owned by user" do
    user = users(:moe)
    outcome = CreateProject.new(MessageHub.new, user).execute(project_options)

    assert outcome.success?
    assert_equal Project.last, outcome.result
    assert_equal user, outcome.result.owner
    assert_equal Site.default, outcome.result.site
  end

  should "create project owned by team" do
    user = users(:mike)
    group = user.groups.first
    outcome = CreateProject.new(MessageHub.new, user).execute(project_options({
          :owner_type => "Group",
          :owner_id => group.id
        }))

    assert outcome.success?
    assert_equal group, outcome.result.owner
    assert_equal user, outcome.result.user
  end

  should "create project under site" do
    user = users(:mike)
    outcome = CreateProject.new(MessageHub.new, user).execute(project_options({
          :site_id => sites(:qt).id
        }))

    assert outcome.success?
    assert_equal sites(:qt), outcome.result.site
  end

  should "create wiki repository" do
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options)

    assert_instance_of Repository, outcome.result.wiki_repository
  end

  should "create default merge request statuses" do
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options)
    statuses = outcome.result.merge_request_statuses

    assert_equal 2, statuses.count
    assert_equal MergeRequest::STATUS_OPEN, statuses.first.state
    assert_equal "Open", statuses.first.name
    assert_equal MergeRequest::STATUS_CLOSED, statuses.last.state
    assert_equal "Closed", statuses.last.name
  end

  should "be added to the creators favorites" do
    user = users(:moe)
    outcome = CreateProject.new(MessageHub.new, user).execute(project_options)

    assert outcome.result.watched_by?(user)
  end

  should "create public project by default" do
    Gitorious.stubs(:private_repositories?).returns(true)
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options)

    assert outcome.result.public?
  end

  should "create private project" do
    Gitorious.stubs(:private_repositories?).returns(true)
    params = project_options({ :private => "1" })
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(params)

    assert outcome.result.private?
    assert can_read?(users(:moe), outcome.result)
  end

  should "create public project" do
    Gitorious.stubs(:private_repositories?).returns(true)
    params = project_options({ :private => "0" })
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(params)

    assert outcome.result.public?
  end

  should "not create private project if not enabled" do
    Gitorious.stubs(:private_repositories?).returns(false)
    params = project_options({ :private => "1" })
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(params)

    assert outcome.result.public?
  end

  should "create event" do
    events = Event.count
    CreateProject.new(MessageHub.new, users(:moe)).execute(project_options)

    assert_equal events + 1, Event.count
  end

  should "require a user" do
    outcome = CreateProject.new(MessageHub.new, nil).execute(project_options)

    refute outcome.success?, outcome.to_s
    assert outcome.pre_condition_failed?, outcome.to_s
  end

  should "prevent user from creating project when project proposals are required" do
    user = users(:moe)
    ProjectProposal.stubs(:required?).with(user).returns(true)
    outcome = CreateProject.new(MessageHub.new, user).execute(project_options)

    refute outcome.success?, outcome.to_s
    assert outcome.pre_condition_failed?, outcome.to_s
  end

  should "reject project failing validation" do
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options(:slug => ""))

    refute outcome.success?, outcome.to_s
    refute_nil outcome.failure.errors[:slug]
  end

  should "limit rate of project creation" do
    user = users(:moe)
    count = Project.count
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options(:slug => "proj1"))
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options(:slug => "proj2"))
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options(:slug => "proj3"))
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options(:slug => "proj4"))
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options(:slug => "proj5"))
    outcome = CreateProject.new(MessageHub.new, users(:moe)).execute(project_options(:slug => "proj6"))

    refute outcome.success?, outcome.to_s
    assert_instance_of ProjectRateLimiting, outcome.pre_condition_failed.pre_condition
    assert_equal count + 5, Project.count
  end

  def project_options(options={})
    { :title => "foo project",
      :slug => "foo",
      :description => "my little project"
    }.merge(options)
  end
end
