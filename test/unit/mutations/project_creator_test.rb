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
require "project_creator"

class ProjectCreatorTest < ActiveSupport::TestCase
  should "create project" do
    user = users(:moe)
    params = {
      "title" => "Big blob",
      "slug" => "big-blob",
      "owner_type" => "User",
      "tag_list" => "",
      "license" => "Academic Free License v3.0",
      "home_url" => "",
      "mailinglist_url" => "",
      "bugtracker_url" => "",
      "wiki_enabled" => "1",
      "description" => "My new project"
    }

    assert_difference("Project.count") do
      outcome = ProjectCreator.run(params, { :user => { :id => user.id } })
      assert outcome.success?, outcome.errors.inspect
      assert_equal "My new project", outcome.result.description
      assert_equal user, outcome.result.owner
    end
  end

  should "create project for user object" do
    assert_difference("Project.count") do
      outcome = ProjectCreator.run({
          "title" => "Big blob",
          "slug" => "big-blob",
          "description" => "My new project",
          "user" => users(:moe)
        })

      assert outcome.success?, outcome.errors.inspect
    end
  end

  should "default owner type to User" do
    user = users(:moe)

    params = {
      "title" => "Big blob",
      "slug" => "big-blob",
      "description" => "My new project"
    }

    outcome = ProjectCreator.run(params, { :user => { :id => user.id } })
    assert_equal user, outcome.result.owner
  end

  should "create project owned by group" do
    group = groups(:team_thunderbird)
    group.add_member(users(:moe), Role.admin)

    outcome = ProjectCreator.run(params(:owner_type => "Group", :owner_id => group.id))
    assert_equal group, outcome.result.owner
  end

  should "create project in specific Site" do
    site = Site.first

    outcome = ProjectCreator.run(params(:site_id => site.id))
    assert_equal site, outcome.result.site
  end

  should "fail for invalid project" do
    params = {
      "slug" => "big-blob",
      "description" => "My new project",
      "user" => { :id => users(:moe).id }
    }

    outcome = ProjectCreator.run(params)
    refute outcome.success?
  end

  should "create public project by default" do
    Gitorious.stubs(:private_repositories?).returns(true)

    outcome = ProjectCreator.run(params)
    assert can_read?(nil, outcome.result)
  end

  should "create private project" do
    Gitorious.stubs(:private_repositories?).returns(true)

    outcome = ProjectCreator.run(params(:private_project => "1"))
    refute can_read?(nil, outcome.result)
    assert can_read?(users(:moe), outcome.result)
  end

  should "create public project" do
    Gitorious.stubs(:private_repositories?).returns(true)

    outcome = ProjectCreator.run(params(:private_project => "0"))
    assert outcome.success?, outcome.errors.inspect
    assert_equal 0, outcome.result.content_memberships.count
  end

  should "not create private project if not enabled" do
    Gitorious.stubs(:private_repositories?).returns(false)

    outcome = ProjectCreator.run(params(:private_project => "1"))
    assert_equal 0, outcome.result.content_memberships.count
  end

  should "create event" do
    assert_difference("Event.count") do
      ProjectCreator.run(params)
    end
  end

  def params(attrs = {})
    {
      "title" => "My project",
      "slug" => "big-blob",
      "description" => "My new project",
      "user" => { "id" => users(:moe).id }
    }.merge(attrs)
  end
end
