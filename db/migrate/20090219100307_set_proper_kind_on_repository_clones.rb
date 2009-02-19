class SetProperKindOnRepositoryClones < ActiveRecord::Migration
  def self.up
    transaction do
      Repository.find(:all, :conditions => "parent_id is not null").each do |repo|
        case repo.owner
        when User
          repo.update_attribute(:kind, Repository::KIND_USER_REPO)
        when Group
          repo.update_attribute(:kind, Repository::KIND_TEAM_REPO)
        else
          say "Don't know what kind #{repo.slug}(#{repo.id}) should be, owner is #{repo.owner.inspect}"
        end
      end
    end
  end

  def self.down
    Repository.update_all("kind = #{Repository::KIND_PROJECT_REPO}", "parent_id is not null")
  end
end
