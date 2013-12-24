class MessageRecipient < ActiveRecord::Base
  self.table_name = :messages_users

  belongs_to :message
  belongs_to :recipient, class_name: 'User'

  def archive!
    update_attribute(:archived, true)
  end

  def unarchive!
    update_attribute(:archived, false)
  end

  def read!
    update_attribute(:read, true)
  end
end
