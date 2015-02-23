#.present encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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

require "digest/sha1"
require "open_id_authentication"

class User < ActiveRecord::Base
  include UrlLinting
  include Gitorious::Authorization

  has_many :projects
  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships
  has_many :repositories, :as => :owner, :conditions => ["kind != ?", Repository::KIND_WIKI],
    :dependent => :destroy
  has_many :cloneable_repositories, :class_name => "Repository",
     :conditions => ["kind != ?", Repository::KIND_TRACKING_REPO]
  has_many :ssh_keys, :order => "id desc", :dependent => :destroy
  has_many :comments
  has_many :email_aliases, :class_name => "Email", :dependent => :destroy
  has_many :events, :order => "events.created_at desc", :dependent => :destroy
  has_many :events_as_target, :class_name => "Event", :as => :target
  has_many :favorites, :dependent => :destroy
  has_many :feed_items, :foreign_key => "watcher_id"
  has_many :content_memberships, :as => :member
  has_many :created_groups, :class_name => "Group", :dependent => :destroy

  has_many :_committerships, :as => :committer, :dependent => :destroy
  def committerships
    UserCommitterships.new(self)
  end

  # Virtual attribute for the unencrypted password
  attr_accessor :password, :password_confirmation, :current_password, :terms_of_use

  after_destroy :expire_avatar_email_caches

  state_machine :aasm_state, :initial => :pending do
    state :terms_accepted

    event :accept_terms do
      transition :pending => :terms_accepted
    end
  end

  Paperclip.interpolates("login") { |attachment, style| attachment.instance.login.downcase }

  avatar_local_path = "/system/:attachment/:login/:style/:basename.:extension"
  has_attached_file :avatar,
    :styles => { :medium => "300x300>", :thumb => "64x64>", :tiny => "24x24>" },
    :url => avatar_local_path,
    :path => ":rails_root/public#{avatar_local_path}"

  def self.human_name
    I18n.t("activerecord.models.user")
  end

  # Authenticates a user by their login name/email and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password)
    collection = where('activated_at IS NOT NULL AND suspended_at IS NULL')

    user = if email.include?('@')
      collection.where("email = ?", email).first
    else
      collection.where("login = ?", email).first
    end

    user && user.authenticated?(password) ? user : nil
  end

  def self.generate_random_password(n = 12)
    SecureRandom.hex(n)
  end

  def self.find_avatar_for_email(email, version)
    Rails.cache.fetch(email_avatar_cache_key(email, version)) do
      result = if u = find_by_email_with_aliases(email)
        if u.avatar?
          u.avatar.url(version)
        end
      end
      result || :nil
    end
  end

  def self.email_avatar_cache_key(email, version)
    "avatar_for_#{Digest::SHA1.hexdigest(email)}_#{version.to_s}"
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

  def self.most_active(limit = 10, cutoff = 3)
    cache_key = "users:most_active_pushers:#{limit}:#{cutoff}"
    select("users.*, events.action, count(events.id) as event_count").
      where("events.action = ? and events.created_at > ?",
            Action::PUSH_SUMMARY,
            cutoff.days.ago).
      joins(:events).
      group("users.id, events.action").
      order("count(events.id) desc").
      limit(limit)
  end

  def self.find_fuzzy(query)
    where("lower(login) like :name or lower(email) like :name",
          { :name => "%" + query.downcase + "%" }).limit(10)
  end

  # A Hash of repository => count of mergerequests active in the
  # repositories that the user is a reviewer in
  def review_repositories_with_open_merge_request_count
    repo_ids = review_repositories(self).select("repository_id")
    mr_repository_ids = repo_ids.map { |c| c.repository_id }
    Repository.
      select("repositories.*, count(merge_requests.id) as open_merge_request_count").
      where("repositories.id in (?) and merge_requests.status = ?",
            mr_repository_ids,
            MergeRequest::STATUS_OPEN).
      group("repositories.id").
      joins(:merge_requests).
      limit(5)
  end

  def activated?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Can this user be shown in public
  def public?
    activated?# && !pending?
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
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
    save(:validate => false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(:validate => false)
  end

  def reset_password!
    generated = User.generate_random_password
    self.password = generated
    self.password_confirmation = generated
    self.save!
    generated
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
    self.crypted_password.blank?
  end

  def suspended?
    !suspended_at.nil?
  end

  def suspend
    self.suspended_at = Time.now
    self.ssh_keys.destroy_all
  end

  def unsuspend
    self.suspended_at = nil
    # Note: user has to reupload ssh keys again
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

  def expire_avatar_email_caches
    avatar.styles.keys.each do |style|
      (email_aliases.map(&:address) << email).each do |email|
        Rails.cache.delete(self.class.email_avatar_cache_key(email, style))
      end
    end
  end

  def watched_objects
    favorites.includes(:watchable).order("id desc").collect(&:watchable)
  end

  def watching?(thing)
    watched_objects.include?(thing)
  end

  def paginated_events_in_watchlist(pagination_options = {})
    key = "paginated_events_in_watchlist:#{self.id}:#{pagination_options[:page] || 1}"
    Rails.cache.fetch(key, :expires_in => 20.minutes) do
      watched = feed_items.paginate({
          :order => "created_at desc",
          :total_entries => FeedItem.per_page+(FeedItem.per_page+1)
        }.merge(pagination_options))

      total = (watched.length < watched.per_page ? watched.length : watched.total_entries)
      items = WillPaginate::Collection.new(watched.current_page, watched.per_page, total)
      items.replace(Event.where(:id => watched.map(&:event_id)).includes(:user, :project, :target).order("created_at desc"))
    end
  end

  def deletable?
    repositories.count == 0 && projects.count == 0 && created_groups_have_no_other_members?
  end

  def created_groups_have_no_other_members?
    created_groups.select { |g| g.members.count > 1 }.empty?
  end

  def self.admins
    User.where(:is_admin => true)
  end

  def uniq_login?
    existing = User.find_by_login(login)
    existing.nil? || existing == self
  end

  def uniq_email?
    existing = User.find_by_email(email)
    existing.nil? || existing == self
  end

  def identity_url=(url)
    self[:identity_url] = normalize_identity_url(url)
  rescue OpenID::DiscoveryFailure
    # validate will catch it instead
    self[:identity_url] = url
  end

  def login=(login)
    self[:login] = (login || "").downcase
  end

  def normalize_identity_url(url)
    OpenID.normalize_url(url)
  end

  def password=(password)
    @password = password
    return @password if password.blank?
    self.salt = self.class.encrypt(login, Time.now.to_s) if !salt?
    self.crypted_password = encrypt(password)
    @password
  end

  def exportable_repositories
    user_repos = repositories.where('kind NOT IN (?)', Repository::KINDS_INTERNAL_REPO)
    group_repos = memberships.where(role_id: Role.admin.id).map(&:group).map(&:repositories).flatten
    (user_repos + group_repos).uniq
  end

  protected
  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  # Encrypts some data with the salt.
  def self.encrypt(data, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{data}--")
  end
end
