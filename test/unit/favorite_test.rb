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
