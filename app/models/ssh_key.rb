class SshKey < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :user_id, :key
  validates_format_of   :key, :with => /^ssh-[a-z0-9]{3,4} .+$/ims
end
