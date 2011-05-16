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

require "tempfile"

class SshKey < ActiveRecord::Base
  include Gitorious::Messaging::Publisher
  belongs_to :user
  
  SSH_KEY_FORMAT = /^ssh\-[a-z0-9]{3,4} [a-z0-9\+=\/]+ SshKey:(\d+)?-User:(\d+)?$/ims.freeze
  
  validates_presence_of :user_id, :key
  
  before_validation { |k| k.key.to_s.strip! }
  before_validation :lint_key!

  # we only allow people to create/destroy keys after_update  :create_update_task 
  after_destroy :publish_deletion_message
  
  def self.human_name
    I18n.t("activerecord.models.ssh_key")
  end
  
  def validate
    if self.to_keyfile_format !~ SSH_KEY_FORMAT
      errors.add(:key, I18n.t("ssh_key.key_format_validation_message"))
    end

    unless valid_key_using_ssh_keygen?
      errors.add(:key, "is not recognized is a valid public key")
    end
  end
  
  def wrapped_key(cols=72)
    key.gsub(/(.{1,#{cols}})/, "\\1\n").strip
  end
  
  def to_key
    %Q{### START KEY #{self.id || "nil"} ###\n} +
    %Q{command="gitorious #{user.login}",no-port-forwarding,} +
    %Q{no-X11-forwarding,no-agent-forwarding,no-pty #{to_keyfile_format}} +
    %Q{\n### END KEY #{self.id || "nil"} ###\n}
  end
  
  # The internal format we use to represent the pubkey for the sshd daemon
  def to_keyfile_format
    %Q{#{self.algorithm} #{self.encoded_key} SshKey:#{self.id}-User:#{self.user_id}}
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
    raise ActiveRecord::RecordInvalid.new(self) if new_record?
    options = ({:target_class => self.class.name, 
      :command => "add_to_authorized_keys", 
      :arguments => [self.to_key], 
      :target_id => self.id,
      :identifier => "ssh_key_#{id}"})

    publish("/queue/GitoriousSshKeys", options)
  end
  
  def publish_deletion_message
    options = ({
      :target_class => self.class.name, 
      :command => "delete_from_authorized_keys", 
      :arguments => [self.to_key],
      :identifier => "ssh_key_#{id}"})

    publish("/queue/GitoriousSshKeys", options)
  end
  
  def components
    key.to_s.strip.split(" ", 3)
  end
  
  def algorithm
    components.first
  end
  
  def encoded_key
    components.second
  end
  
  def comment
    components.last
  end

  def fingerprint
    @fingerprint ||= begin
      raw_blob = encoded_key.to_s.unpack("m*").first
      OpenSSL::Digest::MD5.hexdigest(raw_blob).scan(/../).join(":")
    end
  end

  def valid_key_using_ssh_keygen?
    temp_key = Tempfile.new("ssh_key_#{Time.now.to_i}")
    temp_key.write(self.key)
    temp_key.close
    system("ssh-keygen -l -f #{temp_key.path}")
    temp_key.delete
    return $?.success?
  end
  
  protected
    def lint_key!
      self.key.to_s.gsub!(/(\r|\n)*/m, "")
    end
end
