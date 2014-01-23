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
require "transfer_project_ownership"

class TransferProjectOwnershipTest < ActiveSupport::TestCase
  should "change owner for project" do
    project = projects(:johans)
    user = users(:johan)

    outcome = TransferProjectOwnership.new(Gitorious::App, project, user).execute({
        :owner_type => "User",
        :owner_id => users(:zmalltalker).id
      })

    assert outcome.success?
    assert_equal users(:zmalltalker), outcome.result.owner
  end

  should "make new owner committer on repositories" do
    project = projects(:johans)
    user = users(:johan)

    outcome = TransferProjectOwnership.new(Gitorious::App, project, user).execute({
        :owner_type => "User",
        :owner_id => users(:zmalltalker).id
      })

    assert Gitorious::App.can_push?(users(:zmalltalker), repositories(:johans))
  end

  should "make new owner group members committers on repositories" do
    project = projects(:johans)
    user = users(:johan)
    group = Group.new(:name => "tough-guys")
    group.creator = users(:zmalltalker)
    group.save!
    group.add_member(users(:moe), Role.member)
    group.add_member(users(:zmalltalker), Role.member)
    group.add_member(user, Role.admin)

    outcome = TransferProjectOwnership.new(Gitorious::App, project, user).execute({
        :owner_type => "Group",
        :owner_id => group.id
      })

    assert outcome.success?, [outcome.failure, outcome.pre_condition_failed].inspect
    assert_equal group, project.owner
    assert Gitorious::App.can_push?(users(:zmalltalker), repositories(:johans))
    assert Gitorious::App.can_push?(users(:moe), repositories(:johans))
  end

  should "not allow user to assign ownership to group he is not admin in" do
    project = projects(:johans)
    user = users(:johan)
    group = Group.new(:name => "tough-guys")
    group.creator = users(:zmalltalker)
    group.save!
    group.add_member(users(:moe), Role.member)
    group.add_member(users(:zmalltalker), Role.admin)

    outcome = TransferProjectOwnership.new(Gitorious::App, project, user).execute({
        :owner_type => "Group",
        :owner_id => group.id
      })

    refute outcome.success?
    refute_nil outcome.failure.errors[:owner]
  end

  should "not allow user to assign ownership on project he is not admin" do
    project = projects(:johans)
    user = users(:moe)

    outcome = TransferProjectOwnership.new(Gitorious::App, project, user).execute({
        :owner_type => "Group",
        :owner_id => 2
      })

    assert outcome.pre_condition_failed?
  end

  should "transfer ownership of wiki as well" do
    project = projects(:johans)
    user = users(:johan)
    owner = users(:zmalltalker)

    outcome = TransferProjectOwnership.new(Gitorious::App, project, user).execute({
        :owner_type => "User",
        :owner_id => owner.id
      })

    assert outcome.success?, [outcome.failure, outcome.pre_condition_failed].inspect
    assert_equal owner, project.wiki_repository.owner
  end

  should "promote new owner's existing committership" do
    project = projects(:johans)
    repository = repositories(:johans)
    user = users(:johan)
    owner = users(:zmalltalker)

    c = repository.committerships.create!(:committer => owner, :creator_id => owner.id)
    c.build_permissions(:commit)
    c.save!

    outcome = TransferProjectOwnership.new(Gitorious::App, project, user).execute({
        :owner_type => "User",
        :owner_id => owner.id
      })

    assert outcome.success?, [outcome.failure, outcome.pre_condition_failed].inspect
    assert(repository.committerships.administrators.include?(owner))
  end
end
