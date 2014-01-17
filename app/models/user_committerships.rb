class UserCommitterships
  def initialize(user)
    @user = user
  end

  def reviewers
    user.committerships.reviewers
  end

  def all
    user.committerships
  end

  def count
    all.count
  end

  def commit_repositories
    user.commit_repositories
  end

  def destroy_all
    all.each { |c| c.destroy }
  end

  private

  attr_reader :user
end
