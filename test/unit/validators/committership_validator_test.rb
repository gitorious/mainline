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

class CommittershipValidatorTest < ActiveSupport::TestCase
  setup do
    committership = Committership.new
    @result = CommittershipValidator.call(committership)
  end

  should "validate presence of repository_id" do
    refute_equal [], @result.errors[:repository_id]
  end

  should "validate presence of committer_type" do
    refute_equal [], @result.errors[:committer_type]
  end

  should "validate presence of committer_id" do
    refute_equal [], @result.errors[:committer_id]
  end

  should "be valid with repository_id, committer_type and committer_id" do
    committership = committerships(:johan_johans)

    result = CommittershipValidator.call(committership)

    assert result.errors.empty?
  end

  context "Super Group" do
    setup do
      repository = repositories(:johans)
      @super_group = SuperGroup.super_committership(repository.committerships)
    end

    should "be valid if super group is enabled" do
      Gitorious::Configuration.override("enable_super_group" => true) do
        result = CommittershipValidator.call(@super_group)

        assert result.errors.empty?
      end
    end

    should "be invalid with super group disabled" do
      result = CommittershipValidator.call(@super_group)

      refute result.errors.empty?
    end
  end


  context 'Committership uniqueness' do
    setup do
      @repository = repositories(:johans)
      @repository.committerships.destroy_all
      @owning_group = groups(:team_thunderbird)
    end

    should 'not allow the same user to be added as a committer twice' do
      user = users(:moe)
      @repository.committerships.create!(:committer => user)
      duplicate_committership = @repository.committerships.new_committership(:committer => user)

      result = CommittershipValidator.call(duplicate_committership)
      assert_equal ["is already a committer"], result.errors[:committer_id]
    end

    should 'not allow the same group to be added as a committer twice' do
      @repository.committerships.create!(:committer => @owning_group)
      duplicate_committership = @repository.committerships.new_committership(:committer => @owning_group)
      result = CommittershipValidator.call(duplicate_committership)
      assert_equal ["is already a committer"], result.errors[:committer_id]
    end

    should 'not allow adding the team adding a repository as a committer' do
      @repository.change_owner_to! @owning_group
      new_committership = @repository.committerships.new_committership(:committer => @owning_group)

      result = CommittershipValidator.call(new_committership)
      assert_equal ["is already a committer"], result.errors[:committer_id]
    end
  end
end
