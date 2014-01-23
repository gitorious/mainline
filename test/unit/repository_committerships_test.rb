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
end
