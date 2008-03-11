class Event < ActiveRecord::Base
  belongs_to :action
  belongs_to :user
  belongs_to :repository
  
  def self.from_action_name(action_name, user, repository, ref = nil, body = nil)
    action = Action.find_by_name(action_name)
    return nil if action.nil?
    
    repo_id = nil
    if repository
      repo_id = repository.id
    end
    
    return Event.create(:user_id => user.id, :repository_id => repo_id, :action_id => action.id, 
                        :body => body, :ref => ref, :date => Time.now)
  end
end
