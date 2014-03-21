# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

class RepositoryCommittershipsTest < ActiveSupport::TestCase
  setup do
    repository = repositories(:johans)
    @committerships = repository.committerships
    @johan = users(:johan)
    @johans_committership = committerships(:johan_johans)
    @super_group = SuperGroup.super_committership(@committerships)
  end

  context "#count" do
    should "return the number of committerships" do
      assert_equal 1, @committerships.count
    end

    should "return the number of committerships increased by one with enabled super group" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        assert_equal 2, @committerships.count
      end
    end
  end

  context "#all" do
    should "return all committerships" do
      assert_equal [@johans_committership], @committerships.all
    end

    should "return all committerships with super group" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        assert_equal [@super_group, @johans_committership], @committerships.all
      end
    end

    should "return all committerships without super group if super group was removed" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        @committerships.destroy("super", @johan)
        assert_equal [@johans_committership], @committerships.all
      end
    end
  end

  [:committers, :reviewers, :administrators].each do |filter|
    context filter do
      should "return all #{filter}" do
        assert_equal [@johan], @committerships.send(filter)
      end

      should "return all #{filter} with super group" do
        Gitorious::Configuration.override("enable_super_group" => true) do
          assert_equal User.all, @committerships.send(filter)
        end
      end

      should "return all #{filter} without super group if super group was removed" do
        Gitorious::Configuration.override("enable_super_group" => true) do
          @committerships.destroy("super", @johan)
          assert_equal [@johan], @committerships.send(filter)
        end
      end
    end
  end

  context "#destroy" do
    should "destroy committership" do
      @committerships.destroy(@johans_committership.id, @johan)

      assert_raise ActiveRecord::RecordNotFound do
        @committerships.find(@johans_committership.id)
      end
    end

    should "create a 'removed committer' event on project" do
      assert_difference("@johans_committership.repository.project.events.count") do
        @committerships.destroy(@johans_committership.id, @johan)
      end
      assert_equal Action::REMOVE_COMMITTER, Event.last.action
    end

    should "destroy committership with super groups enabled" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        @committerships.destroy(@johans_committership.id, @johan)

        assert_raise ActiveRecord::RecordNotFound do
          @committerships.find(@johans_committership.id)
        end
      end
    end

    should "should destroy super group with super group enabled" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        @committerships.destroy("super", @johan)

        assert_raise ActiveRecord::RecordNotFound do
          @committerships.find("super")
        end
      end
    end
  end

  context "#find" do
    should "find a committership by id" do
      assert_equal @johans_committership, @committerships.find(@johans_committership.id)
    end

    should "not return super group when it is disabled" do
      assert_raise ActiveRecord::RecordNotFound do
        @committerships.find("super")
      end
    end

    should "find a committership by id with enabled super group" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        assert_equal @johans_committership, @committerships.find(@johans_committership.id)
      end
    end

    should "find super committership with super group enabled" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        assert_equal @super_group, @committerships.find("super")
      end
    end
  end

  context "#users" do
    should "return committerships users" do
      assert_equal [@johans_committership], @committerships.users
    end

    should "return committerships users when super group is enabled" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        assert_equal [@johans_committership], @committerships.users
      end
    end
  end

  context "groups" do
    setup do
      @committership = committerships(:thunderbird_johans)
      @committerships = repositories(:johans2).committerships
    end

    should "return groups" do
      assert_equal [@committership], @committerships.groups
    end

    should "return groups with super group when super group is available" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        assert_equal [@super_group, @committership], @committerships.groups
      end
    end

    should "return original groups if super group is enabled but removed" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        @committerships.destroy("super", @johan)

        assert_equal [@committership], @committerships.groups
      end
    end
  end
end
