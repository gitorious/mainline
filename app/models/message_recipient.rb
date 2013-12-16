class MessageRecipient < ActiveRecord::Base
  self.table_name = :messages_users

  belongs_to :message
  belongs_to :recipient, class_name: 'User'
end
