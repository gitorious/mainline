class SshKey < ActiveRecord::Base
  belongs_to :user
  
  SSH_KEY_FORMAT = /^ssh\-[a-z0-9]{3,4} [a-z0-9\+=\n]+ [a-z0-9_\.\-]*(@[a-z0-9\.\-]*)?$/ims
  
  validates_presence_of :user_id, :key
  validates_format_of   :key, :with => SSH_KEY_FORMAT
  
  before_save   :lint_key!
  after_create  :create_new_task
  # we only allow people to create/destroy keys after_update  :create_update_task 
  after_destroy :create_delete_task
  
  def wrapped_key(cols=72)
    key.gsub(/(.{1,#{cols}})/, "\\1\n").strip
  end
  
  def to_key
    %Q{### START KEY #{self.id || "nil"} ###\n} + 
    %Q{command="gitorious #{user.login}",no-port-forwarding,} + 
    %Q{no-X11-forwarding,no-agent-forwarding,no-pty #{key}} + 
    %Q{\n### END KEY #{self.id || "nil"} ###}
  end 
  
  def self.add_to_authorized_keys(keydata, key_file_class=SshKeyFile)
    key_file = key_file_class.new
    key_file.add_key(keydata)
  end
  
  def self.delete_from_authorized_keys(keydata, key_file_class=SshKeyFile)
    key_file = key_file_class.new
    key_file.delete_key(keydata)
  end
  
  def create_new_task
    Task.create!(:target_class => self.class.name, 
      :command => "add_to_authorized_keys", :arguments => self.to_key)
  end
  
  def create_delete_task
    Task.create!(:target_class => self.class.name, 
      :command => "delete_from_authorized_keys", :arguments => self.to_key)
  end
  
  protected
    def lint_key!
      key.gsub!(/\n*/m, "")
    end
end
