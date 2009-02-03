class MoveProjectRepositoriesToOwner < ActiveRecord::Migration
  def self.up
    transaction do
      Repository.find(:all, :conditions => {:mainline => true}).each do |repo|
        repo.owner = repo.project
        repo.save!
      end
    end
  end

  def self.down
    transaction do
      Repository.find(:all, :conditions => {:mainline => true}).each do |repo|
        repo.owner = repo.project.group
        repo.save!
      end
    end
  end
end
