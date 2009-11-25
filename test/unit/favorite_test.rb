require 'test_helper'

class FavoriteTest < ActiveSupport::TestCase
  context "In general" do
    should_require_attributes(:watchable_type, :watchable_id,
      :user_id)
    should_belong_to :user
    should_belong_to :watchable
  end

  context "Watching a repository" do
    setup do
      @user = Factory.create(:user)
      @project = Factory.create(:project, :user => @user, :owner => @user)
      @repo = Factory.create(:repository, :user => @user, :project => @project, :owner => @user)
    end

    should "work" do
      favorite = @user.favorites.build(:watchable => @repo)
      assert_equal @repo, favorite.watchable
      assert_equal @user, favorite.user
      assert favorite.save
      assert @user.favorites.include?(favorite)
    end
  end
end
