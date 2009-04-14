class MoveProjectRepositoriesToOwner < ActiveRecord::Migration
  def self.up
    transaction do
      Repository.find(:all, :conditions => {:mainline => true}).each do |repo|
        repo.update_attribute(:owner_type, "User")
        repo.update_attribute(:owner_id, repo.project.user_id)
      end
    end
  end

  def self.down
    transaction do
      Repository.find(:all, :conditions => {:mainline => true}).each do |repo|
        repo.update_attribute(:owner_type, "Group")
        repo.update_attribute(:owner_id, repo.project.group.id)
      end
    end
  end
end
