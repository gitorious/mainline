class UserCommitterships
  def initialize(user)
    @user = user
  end

  def reviewers
    user.committerships.reviewers
  end

  private

  attr_reader :user
end
