# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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

require 'test_helper'

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

    should "work" do
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
end
