# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

require 'digest/sha1'

class User < ActiveRecord::Base
  include UrlLinting
  
  has_many :projects
  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships
  has_many :repositories, :as => :owner, :conditions => ["kind != ?", Repository::KIND_WIKI],
    :dependent => :destroy
  has_many :committerships, :as => :committer
  has_many :commit_repositories, :through => :committerships, :source => :repository,
    :conditions => ["repositories.kind != ?", Repository::KIND_WIKI]
  has_many :ssh_keys, :order => "id desc"
  has_many :comments
  has_many :events, :order => "events.created_at asc", :dependent => :destroy
  has_many :email_aliases, :class_name => "Email"
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password, :current_password

  attr_protected :login, :is_admin

  # For new users we are a little more strict than for existing ones. 
  USERNAME_FORMAT = /[a-z0-9\-_\.]+/i.freeze
  USERNAME_FORMAT_ON_CREATE = /[a-z0-9\-]+/.freeze
  validates_presence_of     :login, :email,               :if => :password_required?
  validates_format_of       :login, :with => /^#{USERNAME_FORMAT_ON_CREATE}$/i, :on => :create
  validates_format_of       :login, :with => /^#{USERNAME_FORMAT}$/i, :on => :update
  validates_format_of       :email, :with => Email::FORMAT
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  
  validates_acceptance_of :end_user_license_agreement, :on => :create, :allow_nil => false
  
  before_save :encrypt_password
  before_create :make_activation_code
  before_validation :lint_identity_url, :downcase_login

  state_machine :aasm_state, :initial => :pending do
    state :terms_accepted
    
    event :accept_terms do
      transition :pending => :terms_accepted
    end
    
  end
  
  has_many :received_messages, :class_name => "Message", :foreign_key => 'recipient_id', :order => "created_at DESC" do
    def unread
      find(:all, :conditions => {:aasm_state => "unread"})
    end
    
    def top_level
      find(:all, :conditions => {:in_reply_to_id => nil})
    end
    
    def unread_count
      count(:all, :conditions => {:aasm_state => "unread"})
    end
  end

  Paperclip::Attachment.interpolations['login'] = lambda{|attachment,style| attachment.instance.login}
  
  avatar_local_path = '/system/:attachment/:login/:style/:basename.:extension'
  has_attached_file :avatar, 
    :styles => { :medium => "300x300>", :thumb => "64x64>" },
    :url => avatar_local_path,
    :path => ":rails_root/public#{avatar_local_path}"

  # Top level messages either from or to me
  def top_level_messages
    Message.find_by_sql(["SELECT * FROM messages WHERE (sender_id=? OR recipient_id=?) AND in_reply_to_id IS NULL ORDER BY created_at DESC", self,self])
  end
  
  has_many :sent_messages, :class_name => "Message", :foreign_key => "sender_id", :order => "created_at DESC" do
    def top_level
      find(:all, :conditions => {:in_reply_to_id => nil})
    end
  end
  
  def self.human_name
    I18n.t("activerecord.models.user")
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password)
    u = find :first, :conditions => ['email = ? and activated_at IS NOT NULL and suspended_at IS NULL', email] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def self.generate_random_password(n = 12)
    ActiveSupport::SecureRandom.hex(n)
  end
  
  def self.generate_reset_password_key(n = 16)
    ActiveSupport::SecureRandom.hex(n)
  end
  
  def self.find_avatar_for_email(email, version)
    Rails.cache.fetch("avatar_for_#{email}_#{version.to_s}") do
      result = if u = find_by_email_with_aliases(email)
        if u.avatar?
          u.avatar.url(version)
        end
      end
      result || :nil
    end
  end
  
  # Finds a user either by his/her primary email, or one of his/hers aliases
  def self.find_by_email_with_aliases(email)
    user = User.find_by_email(email)
    unless user
      if email_alias = Email.find_confirmed_by_address(email)
        user = email_alias.user
      end
    end
    user
  end
  
  def self.most_active(limit = 10)
    find(:all, :select => "users.*, count(events.id) as event_count",
      :joins => :events, :group => "users.id", :order => "event_count desc",
      :limit => limit)
  end
  
  def validate
    if !not_openid?
      begin
        OpenIdAuthentication.normalize_identifier(self.identity_url)
      rescue OpenIdAuthentication::InvalidOpenId => e
        errors.add(:identity_url, I18n.t( "user.invalid_url" ))
      end
    end
  end
  
  # Activates the user in the database.
  def activate
    @activated = true
    self.attributes = {:activated_at => Time.now.utc, :activation_code => nil}
    save(false)
  end

  def activated?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  # Can this user be shown in public
  def public?
    activated? && !pending?
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def breadcrumb_parent
    nil
  end

  def current_license_agreement_accepted?
    EndUserLicenseAgreement.current_version.checksum == accepted_license_agreement_version
  end
  
  def eula_version=(checksum)
    self.accepted_license_agreement_version = checksum
    if current_license_agreement_accepted? && self.pending?
      self.accept_terms!
    end
  end
  
  def eula_version
    accepted_license_agreement_version
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  def reset_password!
    generated = User.generate_random_password
    self.password = generated
    self.password_confirmation = generated
    self.save!
    generated
  end
  
  def forgot_password!
    generated_key = User.generate_reset_password_key
    self.password_key = generated_key
    self.save!
    generated_key
  end

  def can_write_to?(repository)
    repository.writable_by?(self)
  end

  def to_param
    login
  end
  
  def to_param_with_prefix
    "~#{to_param}"
  end

  def to_xml(opts = {})
    super({ :only => [:login, :created_at, :fullname, :url] }.merge(opts))
  end
  
  def is_openid_only?
    self.crypted_password.nil?
  end
  
  def suspended?
    !suspended_at.nil?
  end
  
  def site_admin?
    is_admin
  end
  
  # is +a_user+ an admin within this users realm
  # (for duck-typing repository etc access related things)
  def admin?(a_user)
    self == a_user
  end
  
  # is +a_user+ a committer within this users realm
  # (for duck-typing repository etc access related things)
  def committer?(a_user)
    self == a_user
  end
  
  def to_grit_actor
    Grit::Actor.new(fullname.blank? ? login : fullname, email)
  end
  
  def title
    fullname.blank? ? login : fullname
  end
  
  def in_openid_import_phase!
    @in_openid_import_phase = true
  end

  def in_openid_import_phase?
    return @in_openid_import_phase
  end
  
  def url=(an_url)
    self[:url] = clean_url(an_url)
  end

  protected
    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      not_openid? && (crypted_password.blank? || !password.blank?)
    end

    def not_openid?
      identity_url.blank?
    end

    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
    
    def lint_identity_url
      return if not_openid?
      self.identity_url = OpenIdAuthentication.normalize_identifier(self.identity_url)
    rescue OpenIdAuthentication::InvalidOpenId
      # validate will catch it instead
    end
    
    def downcase_login
      login.downcase! if login
    end
end
