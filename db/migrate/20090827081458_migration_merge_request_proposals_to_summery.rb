# encoding: utf-8

class MigrationMergeRequestProposalsToSummery < ActiveRecord::Migration
  def self.up
    transaction do
      MergeRequest.all.each do |mr|
        if mr.proposal.blank?
          mr.summary = "..."
          mr.save!
          next
        end
        mr.summary = mr.proposal.encode("utf-8",
            :undef => :replace, :invalid => :replace, :replace => "?")[0..75]
        mr.summary << '...' if mr.proposal.length > 75
        mr.save!
      end
    end
  end

  def self.down
  end
end
