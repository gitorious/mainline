# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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
  include ActiveMessaging::MessageSender
  belongs_to :user
  
  SSH_KEY_FORMAT = /^ssh\-[a-z0-9]{3,4} [a-z0-9\+=\/]+ [a-z0-9_\.\-\ \+\/:]*(@[a-z0-9\.\-_]*)?$/ims
  
  validates_presence_of :user_id, :key
  validates_format_of   :key, :with => SSH_KEY_FORMAT
  
  before_validation { |k| k.key.to_s.strip! }
  before_validation   :lint_key!
  after_create  :publish_creation_message
  # we only allow people to create/destroy keys after_update  :create_update_task 
  after_destroy :publish_deletion_message
  
  def self.human_name
    I18n.t("activerecord.models.ssh_key")
  end
  
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
  
  def publish_creation_message
    options = ({:target_class => self.class.name, 
      :command => "add_to_authorized_keys", 
      :arguments => [self.to_key], 
      :target_id => self.id,
      :identifier => "ssh_key_#{id}"})
    publish :ssh_key_generation, options.to_json
  end
  
  def publish_deletion_message
    options = ({
      :target_class => self.class.name, 
      :command => "delete_from_authorized_keys", 
      :arguments => [self.to_key],
      :identifier => "ssh_key_#{id}"})
    publish :ssh_key_generation, options.to_json
  end
  
  def algorithm
    key.strip.split(" ").first
  end
  
  def username_and_host
    key.strip.split(" ").last
  end
  
  def encoded_key
    key.strip.split(" ").second
  end
  
  protected
    def lint_key!
      self.key.gsub!(/(\r|\n)*/m, "")
    end
end
