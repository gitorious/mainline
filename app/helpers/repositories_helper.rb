module RepositoriesHelper
  # Returns a Hash {email => user}
  def self.users_by_commits(commits)
    emails = commits.map { |commit| commit.committer.email }
    users = User.find(:all, :conditions => ["email in (?)", emails])
    email_user = {}
    users.each { |user|
      email_user[user.email] = user
    }
    
    email_user
  end
end
