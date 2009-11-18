class MigrateMergeRequestsToStatusTag < ActiveRecord::Migration
  def self.up
    MergeRequest.all.each { |mr|
      mr.migrate_to_status_tag
    }
  end

  def self.down
  end
end
