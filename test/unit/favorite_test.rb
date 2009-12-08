# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

require File.dirname(__FILE__) + '/../test_helper'

class FavoriteTest < ActiveSupport::TestCase
  def create_favorited_repo
    user = Factory.create(:user)
    project = Factory.create(:project, :user => user, :owner => user)
    repo = Factory.create(:repository, :user => user, :project => project, :owner => user)
    [user, project, repo]
  end

  context "In general" do
    should_require_attributes(:watchable_type, :watchable_id,
      :user_id)
    should_belong_to :user
    should_belong_to :watchable
    should_validate_uniqueness_of :user_id, :scoped_to => [:watchable_id, :watchable_type]
  end

  context "Watching a repository" do
    setup do
      @user, @project, @repo = create_favorited_repo
    end

    should "be linked with user's favorites" do
      favorite = @user.favorites.build(:watchable => @repo)
      assert_equal @repo, favorite.watchable
      assert_equal @user, favorite.user
      assert favorite.save
      assert @user.favorites.include?(favorite)
    end

    should "give access to the watched object" do
      favorite = @user.favorites.create(:watchable => @repo)
      assert @user.watched_objects.include?(@repo)
    end

    should "know if the user watches the repo" do
      assert !@repo.watched_by?(@user)
      favorite = @user.favorites.create(:watchable => @repo)
      @repo.favorites.reload
      assert @repo.watched_by?(@user)
    end
  end

  context "Generating events after creation" do
    setup {
      @user, @project, @repo = create_favorited_repo
    }

    should "create an event when a favorite is created" do
      favorite = @user.favorites.build(:watchable => @repo)
      assert !favorite.event_exists?
      assert favorite.save
      assert_not_nil(favorite_event = @user.events_as_target.last)
      assert favorite.event_exists?
    end

    should "only create an event the first time" do
      favorite = @user.favorites.create(:watchable => @repo)
      assert favorite.event_exists?
      favorite.destroy
      new_favorite = @user.favorites.build(:watchable => @repo)
      assert new_favorite.event_exists?
      assert_incremented_by @user.events_as_target, :count, 0 do
        assert new_favorite.save
      end
    end
  end

  context "Watching merge requests" do
    setup {
      @user = users(:mike)
    }

    should "return the target repository's project as project" do
      merge_request = merge_requests(:moes_to_johans)
      favorite = @user.favorites.create(:watchable => merge_request)
      assert_equal(merge_request.target_repository.project,
        favorite.project)
    end
  end

  context "Watching projects" do
    setup {
      @user = users(:moe)
    }

    should "return the project as project" do
      @project = projects(:johans)
      favorite = @user.favorites.create(:watchable => @project)
      assert_equal @project, favorite.project
    end
  end

end
