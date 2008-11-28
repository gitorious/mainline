#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class SshKey < ActiveRecord::Base
  belongs_to :user
  
  SSH_KEY_FORMAT = /^ssh\-[a-z0-9]{3,4} [a-z0-9\+=\/]+ [a-z0-9_\.\-\ \+\/:]*(@[a-z0-9\.\-]*)?$/ims
  
  validates_presence_of :user_id, :key
  validates_format_of   :key, :with => SSH_KEY_FORMAT
  
  before_validation { |k| k.key.to_s.strip! }
  before_validation   :lint_key!
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
    %Q{\n### END KEY #{self.id || "nil"} ###\n}
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
      :command => "add_to_authorized_keys", 
      :arguments => [self.to_key], 
      :target_id => self.id)
  end
  
  def create_delete_task
    Task.create!(:target_class => self.class.name, 
      :command => "delete_from_authorized_keys", :arguments => [self.to_key])
  end
  
  protected
    def lint_key!
      self.key.gsub!(/(\r|\n)*/m, "")
    end
end
