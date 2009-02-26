class MigratingStatusOfMergeRequests < ActiveRecord::Migration
  def self.up
    MergeRequest.update_all("status=status+1")
  end

  def self.down
    say "Will NOT change the statuses down, your MergeRequests will have invalid statuses"
  end
end
