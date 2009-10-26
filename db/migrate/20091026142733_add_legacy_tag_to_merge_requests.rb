class AddLegacyTagToMergeRequests < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :merge_requests, :legacy, :boolean, :default => false
      ActiveRecord::Base.reset_column_information
      merge_requests = MergeRequest.find(:all, :include => :versions,
        :conditions => ["status != ? and created_at < ?",
                        MergeRequest::STATUS_PENDING_ACCEPTANCE_OF_TERMS,
                       1.week.ago])
      merge_requests.reject!{|mr| !mr.versions.blank? }
      say "Marking #{merge_requests.size} merge requests as legacy"
      merge_requests.each do |mr|
        mr.update_attribute(:legacy, true)
      end
    end
  end

  def self.down
    remove_column :merge_requests, :legacy
  end
end
