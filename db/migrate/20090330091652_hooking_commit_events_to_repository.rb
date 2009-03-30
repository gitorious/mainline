# This migration changes the relationships for the events created for comments
# Instead of being related to the actual comment, the target is set to be the repository
# Further on, the id of the comment (we can assume there is one, since this is a comment type event), 
# is stored in the data field instead of the target
class HookingCommitEventsToRepository < ActiveRecord::Migration
  def self.up
    events = Event.find_all_by_action(Action::COMMENT)
    events.each do |event|
      comment_id = event.target.id
      repository = Repository.find(event.target.target_id)  # The event's target has a target_id being the ID of the repository
      event.update_attributes(:target_type => 'Repository', :target_id => repository.id, :data => comment_id)
    end
  end

  def self.down
    events = Event.find_all_by_action(Action::COMMENT)
    events.each do |event|
      comment = Comment.find(event.data)
      event.update_attributes(:target_type => 'Comment', :target_id => comment.id, :data => nil)
    end
  end
end
