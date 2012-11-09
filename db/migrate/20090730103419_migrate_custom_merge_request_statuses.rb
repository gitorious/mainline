module Gitorious
  class Project < ActiveRecord::Base
    default_scope :conditions => {}
  end
end

class MigrateCustomMergeRequestStatuses < ActiveRecord::Migration
  def self.up
    transaction do
      Gitorious::Project.all.each do |project|
        if !project.merge_request_custom_states.blank?
          project.merge_request_custom_states.each do |open_state|
            project.merge_request_statuses.create!({
                :name => open_state,
                :state => MergeRequest::STATUS_OPEN,
                :color => "#408000" # green-ish
              })
          end
        else
          project.merge_request_statuses.create!({
              :name => "Open",
              :state => MergeRequest::STATUS_OPEN,
              :color => "#408000"
          })
        end

        ["Merged", "Rejected"].each do |closed_state|
          project.merge_request_statuses.create!({
              :name => closed_state,
              :state => MergeRequest::STATUS_CLOSED,
              :color => "#AA0000" # red-ish
          })
        end
      end
    end
  end

  def self.down
    transaction do
      Gitorious::Project.all.each do |project|
        project.merge_request_statuses.each do |state|
          next unless state.open?
          project.merge_request_custom_states << state.name
          project.merge_request_custom_states.uniq!
          project.save!
        end
      end
    end
  end
end
