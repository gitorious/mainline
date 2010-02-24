class AddingRequestCountersToHooks < ActiveRecord::Migration
  def self.up
    add_column :hooks, :failed_request_count, :integer, :default => 0
    add_column :hooks, :successful_request_count, :integer, :default => 0
  end

  def self.down 
    remove_column :hooks, :failed_request_count
    remove_column :hooks, :successful_request_count
  end
end
