# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 David Aguilar <davvid@gmail.com>
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
require "gitorious/reservations"
require "gitorious/messaging"

class Repository < ActiveRecord::Base
  include Gitorious::Messaging::Publisher
  include RecordThrottling
  include Watchable
  include Gitorious::Search

  KIND_PROJECT_REPO = 0
  KIND_WIKI = 1
  KIND_TEAM_REPO = 2
  KIND_USER_REPO = 3
  KIND_TRACKING_REPO = 4
  KINDS_INTERNAL_REPO = [KIND_WIKI, KIND_TRACKING_REPO]

  WIKI_NAME_SUFFIX = "-gitorious-wiki"
  WIKI_WRITABLE_EVERYONE = 0
  WIKI_WRITABLE_PROJECT_MEMBERS = 1

  belongs_to  :user
  belongs_to  :project
  belongs_to  :owner, :polymorphic => true
  has_many    :committerships, :dependent => :destroy
  belongs_to  :parent, :class_name => "Repository"
  has_many    :clones, :class_name => "Repository", :foreign_key => "parent_id",
    :dependent => :nullify
  has_many    :comments, :as => :target, :dependent => :destroy
  has_many    :merge_requests, :foreign_key => 'target_repository_id',
    :order => "status, id desc", :dependent => :destroy
  has_many    :proposed_merge_requests, :foreign_key => 'source_repository_id',
                :class_name => 'MergeRequest', :order => "id desc", :dependent => :destroy
  has_many    :cloners, :dependent => :destroy
  has_many    :events, :as => :target, :dependent => :destroy
  has_many :hooks, :dependent => :destroy

  NAME_FORMAT = /[a-z0-9_\-]+/i.freeze
  validates_presence_of :user_id, :name, :owner_id, :project_id
  validates_format_of :name, :with => /^#{NAME_FORMAT}$/i,
    :message => "is invalid, must match something like /[a-z0-9_\\-]+/"
  validates_exclusion_of :name,
    :in => (Gitorious::Reservations.project_names + Gitorious::Reservations.repository_names)
  validates_uniqueness_of :name, :scope => :project_id, :case_sensitive => false
  validates_uniqueness_of :hashed_path, :case_sensitive => false

  before_validation :downcase_name
  before_create :set_repository_hash
  after_create :create_initial_committership
  after_create :create_add_event_if_project_repo
  after_create :post_repo_creation_message
  after_create :add_owner_as_watchers
  after_destroy :post_repo_deletion_message

  throttle_records :create, :limit => 5,
    :counter => proc{|record|
      record.user.repositories.count(:all, :conditions => ["created_at > ?", 5.minutes.ago])
    },
    :conditions => proc{|record| {:user_id => record.user.id} },
    :timeframe => 5.minutes

  named_scope :by_users,  :conditions => { :kind => KIND_USER_REPO } do
    def fresh(limit = 10)
      find(:all, :order => "last_pushed_at DESC", :limit => limit)
    end
  end
  named_scope :by_groups, :conditions => { :kind => KIND_TEAM_REPO } do
    def fresh(limit=10)
      find(:all, :order => "last_pushed_at DESC", :limit => limit)
    end
  end
  named_scope :clones,    :conditions => ["kind in (?) and parent_id is not null",
                                          [KIND_TEAM_REPO, KIND_USER_REPO]]
  named_scope :mainlines, :conditions => { :kind => KIND_PROJECT_REPO }

  named_scope :regular, :conditions => ["kind in (?)", [KIND_TEAM_REPO, KIND_USER_REPO,
                                                       KIND_PROJECT_REPO]]
  is_indexed do |s|
    s.index :name
    s.index :description
    s.index "project#slug", :as => :project
    s.conditions "kind in (#{[KIND_PROJECT_REPO, KIND_TEAM_REPO, KIND_USER_REPO].join(',')})"
  end

  def self.human_name
    I18n.t("activerecord.models.repository")
  end

  def self.new_by_cloning(other, username=nil)
    suggested_name = username ? "#{username}s-#{other.name}" : nil
    new(:parent => other, :project => other.project, :name => suggested_name,
      :merge_requests_enabled => other.merge_requests_enabled)
  end

  def self.find_by_name_in_project!(name, containing_project = nil)
    if containing_project
      find_by_name_and_project_id!(name, containing_project.id)
    else
      find_by_name!(name)
    end
  end

  def self.find_by_path(path)
    base_path = path.gsub(/^#{Regexp.escape(GitoriousConfig['repository_base_path'])}/, "")
    path_components = base_path.split("/").reject{|p| p.blank? }
    repo_name, owner_name = [path_components.pop, path_components.shift]
    project_name = path_components.pop
    repo_name.sub!(/\.git/, "")

    owner = case owner_name[0].chr
      when "+"
        Group.find_by_name!(owner_name.sub(/^\+/, ""))
      when "~"
        User.find_by_login!(owner_name.sub(/^~/, ""))
      else
        Project.find_by_slug!(owner_name)
      end

    if owner.is_a?(Project)
      owner_conditions = { :project_id => owner.id }
    else
      owner_conditions = { :owner_type => owner.class.name, :owner_id => owner.id }
    end
    if project_name
      if project = Project.find_by_slug(project_name)
        owner_conditions.merge!(:project_id => project.id)
      end
    end
    Repository.find(:first, :conditions => {:name => repo_name}.merge(owner_conditions))
  end

  def self.create_git_repository(path)
    full_path = full_path_from_partial_path(path)
    git_backend.create(full_path)

    self.create_hooks(full_path)
  end

  def self.clone_git_repository(target_path, source_path, options = {})
    full_path = full_path_from_partial_path(target_path)
    Grit::Git.with_timeout(nil) do
      git_backend.clone(full_path,
        full_path_from_partial_path(source_path))
    end
    self.create_hooks(full_path) unless options[:skip_hooks]
  end

  def self.delete_git_repository(path)
    git_backend.delete!(full_path_from_partial_path(path))
  end

  def self.most_active_clones_in_projects(projects, limit = 5)
    key = "repository:most_active_clones_in_projects:#{projects.map(&:id).join('-')}:#{limit}"
    Rails.cache.fetch(key, :expires_in => 2.hours) do
      clone_ids = projects.map do |project|
        project.repositories.clones.map{|r| r.id }
      end.flatten
      find(:all, :limit => limit,
        :select => 'distinct repositories.*, count(events.id) as event_count',
        :order => "event_count desc", :group => "repositories.id",
        :conditions => ["repositories.id in (?) and events.created_at > ? and kind in (?)",
                        clone_ids, 7.days.ago, [KIND_USER_REPO, KIND_TEAM_REPO]],
        #:conditions => { :id => clone_ids },
        :joins => :events, :include => :project)
    end
  end

  def self.most_active_clones(limit = 10)
    Rails.cache.fetch("repository:most_active_clones:#{limit}", :expires_in => 2.hours) do
      find(:all, :limit => limit,
        :select => 'distinct repositories.id, repositories.*, count(events.id) as event_count',
        :order => "event_count desc", :group => "repositories.id",
        :conditions => ["events.created_at > ? and kind in (?)",
                        7.days.ago, [KIND_USER_REPO, KIND_TEAM_REPO]],
        :joins => :events, :include => :project)
    end
  end

  # Finds all repositories that might be due for a gc, starting with
  # the ones who've been pushed to recently
  def self.all_due_for_gc(batch_size = 25)
    find(:all,
      :order => "push_count_since_gc desc",
      :conditions => "push_count_since_gc > 0",
      :limit => batch_size)
  end

  def gitdir
    "#{url_path}.git"
  end

  def url_path
    if project_repo?
      File.join(project.to_param_with_prefix, name)
    else
      File.join(owner.to_param_with_prefix, project.slug, name)
    end
  end

  def real_gitdir
    "#{self.full_hashed_path}.git"
  end

  def browse_url
    "#{GitoriousConfig['scheme']}://#{GitoriousConfig['gitorious_host']}/#{url_path}"
  end

  def default_clone_url
    return git_clone_url if git_cloning?
    return http_clone_url if http_cloning?
    ssh_clone_url
  end

  def clone_url
    "git://#{GitoriousConfig['gitorious_host']}/#{gitdir}"
  end

  def ssh_clone_url
    push_url
  end

  def git_clone_url
    clone_url
  end

  def http_clone_url
    "#{GitoriousConfig['scheme']}://#{Site::HTTP_CLONING_SUBDOMAIN}.#{GitoriousConfig['gitorious_host']}/#{gitdir}"
  end

  def http_cloning?
    !GitoriousConfig["hide_http_clone_urls"]
  end

  def git_cloning?
    !GitoriousConfig["hide_git_clone_urls"]
  end

  def ssh_cloning?
    true
  end

  def push_url
    "#{GitoriousConfig['gitorious_user']}@#{GitoriousConfig['gitorious_host']}:#{gitdir}"
  end

  def display_ssh_url?(user)
    return true if GitoriousConfig["always_display_ssh_url"]
    writable_by?(user)
  end

  def full_repository_path
    self.class.full_path_from_partial_path(real_gitdir)
  end

  def git
    Grit::Repo.new(full_repository_path)
  end

  def has_commits?
    return false if new_record? || !ready?
    !git.heads.empty?
  end

  def self.git_backend
    RAILS_ENV == "test" ? MockGitBackend : GitBackend
  end

  def git_backend
    RAILS_ENV == "test" ? MockGitBackend : GitBackend
  end

  def to_param
    name
  end

  def to_xml(opts = {})
    info_proc = Proc.new do |options|
      builder = options[:builder]
      builder.owner(owner.to_param, :kind => (owned_by_group? ? "Team" : "User"))
      builder.kind(["mainline", "wiki", "team", "user"][self.kind])
      builder.project(project.to_param)
    end

    super({
      :procs => [info_proc],
      :only => [:name, :created_at, :ready, :description, :last_pushed_at],
      :methods => [:clone_url, :push_url, :parent]
    }.merge(opts))
  end

  def head_candidate
    return nil unless has_commits?
    @head_candidate ||= head || git.heads.first
  end

  def head_candidate_name
    if head = head_candidate
      head.name
    end
  end

  def head
    git.head
  end

  def head=(head_name)
    if new_head = git.heads.find{|h| h.name == head_name }
      unless git.head == new_head
        git.update_head(new_head)
      end
    end
  end

  def last_commit(ref = nil)
    if has_commits?
      @last_commit ||= Array(git.commits(ref || head_candidate.name, 1)).first
    end
    @last_commit
  end

  def commit_for_tree_path(ref, commit_id, path)
    Rails.cache.fetch("treecommit:#{commit_id}:#{Digest::SHA1.hexdigest(ref+path)}") do
      git.log(ref, path, {:max_count => 1}).first
    end
  end

  def can_be_deleted_by?(candidate)
    admin?(candidate)
  end

  # Can +a_user+ request a merge from this repository
  def can_request_merge?(a_user)
    !mainline? && writable_by?(a_user)
  end

  # changes the owner to +another_owner+, removes the old owner as committer
  # and adds +another_owner+ as committer
  def change_owner_to!(another_owner)
    unless owned_by_group?
      transaction do
        if existing = committerships.find_by_committer_id_and_committer_type(owner.id, owner.class.name)
          existing.destroy
        end
        self.owner = another_owner
        if self.kind != KIND_PROJECT_REPO
          case another_owner
          when Group
            self.kind = KIND_TEAM_REPO
          when User
            self.kind = KIND_USER_REPO
          end
        end
        unless committerships.any?{|c|c.committer == another_owner}
          committerships.create_for_owner!(self.owner)
        end
        save!
        reload
      end
    end
  end

  def post_repo_creation_message
    return if tracking_repo?

    payload = {
      :target_class => self.class.name,
      :target_id => self.id,
      :command => parent ? 'clone_git_repository' : 'create_git_repository',
      :arguments => parent ? [real_gitdir, parent.real_gitdir] : [real_gitdir]
    }

    publish("/queue/GitoriousRepositoryCreation", payload)
  end

  def post_repo_deletion_message
    payload = {
      :target_class => self.class.name,
      :command => 'delete_git_repository',
      :arguments => [real_gitdir]
    }

    publish("/queue/GitoriousRepositoryDeletion", payload)
  end

  def total_commit_count
    events.count(:conditions => {:action => Action::COMMIT})
  end

  def paginated_commits(ref, page, per_page = 30)
    page    = (page || 1).to_i
    begin
      total = git.commit_count(ref)
    rescue Grit::Git::GitTimeout
      total = 2046
    end
    offset  = (page - 1) * per_page
    commits = WillPaginate::Collection.new(page, per_page, total)
    commits.replace git.commits(ref, per_page, offset)
  end

  def cached_paginated_commits(ref, page, per_page = 30)
    page = (page || 1).to_i
    last_commit_id = last_commit(ref) ? last_commit(ref).id : nil
    total = Rails.cache.fetch("paglogtotal:#{self.id}:#{last_commit_id}:#{ref}") do
      begin
        git.commit_count(ref)
      rescue Grit::Git::GitTimeout
        2046
      end
    end
    Rails.cache.fetch("paglog:#{page}:#{self.id}:#{last_commit_id}:#{ref}") do
      offset = (page - 1) * per_page
      commits = WillPaginate::Collection.new(page, per_page, total)
      commits.replace git.commits(ref, per_page, offset)
    end
  end

  def count_commits_from_last_week_by_user(user)
    return 0 unless has_commits?

    commits_by_email = git.commits_since("master", "last week").collect do |commit|
      commit.committer.email == user.email
    end
    commits_by_email.size
  end

  # TODO: cache
  def commit_graph_data(head = "master")
    commits = git.commits_since(head, "24 weeks ago")
    commits_by_week = commits.group_by{|c| c.committed_date.strftime("%W") }

    # build an initial empty set of 24 week commit data
    weeks = [1.day.from_now-1.week]
    23.times{|w| weeks << weeks.last-1.week }
    week_numbers = weeks.map{|d| d.strftime("%W") }
    commits = (0...24).to_a.map{|i| 0 }

    commits_by_week.each do |week, commits_in_week|
      if week_pos = week_numbers.index(week)
        commits[week_pos+1] = commits_in_week.size
      end
    end
    commits = [] if commits.max == 0
    [week_numbers.reverse, commits.reverse]
  end

  # TODO: caching
  def commit_graph_data_by_author(head = "master")
    h = {}
    emails = {}
    data = self.git.git.shortlog({:e => true, :s => true }, head)
    data.each_line do |line|
      count, actor = line.split("\t")
      actor = Grit::Actor.from_string(actor)

      h[actor.name] ||= 0
      h[actor.name] += count.to_i
      emails[actor.email] = actor.name
    end

    users = User.find(:all, :conditions => ["email in (?)", emails.keys])
    users.each do |user|
      author_name = emails[user.email]
      if h[author_name] # in the event that a user with the same name has used two different emails, he'd be gone by now
        h[user.login] = h.delete(author_name)
      end
    end

    h
  end

  # Returns a Hash {email => user}, where email is selected from the +commits+
  def users_by_commits(commits)
    emails = commits.map { |commit| commit.author.email }.uniq
    users = User.find(:all, :conditions => ["email in (?)", emails])

    users_by_email = users.inject({}){|hash, user| hash[user.email] = user; hash }
    users_by_email
  end

  def cloned_from(ip, country_code = "--", country_name = nil, protocol = 'git')
    cloners.create(:ip => ip, :date => Time.now.utc, :country_code => country_code, :country => country_name, :protocol => protocol)
  end

  def wiki?
    kind == KIND_WIKI
  end

  def project_repo?
    kind == KIND_PROJECT_REPO
  end

  def mainline?
    project_repo?
  end

  def team_repo?
    kind == KIND_TEAM_REPO
  end

  def user_repo?
    kind == KIND_USER_REPO
  end

  def tracking_repo?
    kind == KIND_TRACKING_REPO
  end

  # returns an array of users who have commit bits to this repository either
  # directly through the owner, or "indirectly" through the associated groups
  def committers
    committerships.committers.map{|c| c.members }.flatten.compact.uniq
  end

  # Returns a list of Users who can review things (as per their Committership)
  def reviewers
    committerships.reviewers.map{|c| c.members }.flatten.compact.uniq
  end

  # The list of users who can admin this repo, either directly as
  # committerships or indirectly as members of a group
  def administrators
    committerships.admins.map{|c| c.members }.flatten.compact.uniq
  end

  def committer?(a_user)
    a_user.is_a?(User) ? self.committers.include?(a_user) : false
  end

  def reviewer?(a_user)
    a_user.is_a?(User) ? self.reviewers.include?(a_user) : false
  end

  def admin?(a_user)
    a_user.is_a?(User) ? self.administrators.include?(a_user) : false
  end

  # Is this repo writable by +a_user+, eg. does he have push permissions here
  # NOTE: this may be context-sensitive depending on the kind of repo
  def writable_by?(a_user)
    if wiki?
      wiki_writable_by?(a_user)
    else
      committers.include?(a_user)
    end
  end

  def owned_by_group?
    owner === Group
  end

  def breadcrumb_parent
    if mainline?
      project
    else
      owner
    end
  end

  def title
    name
  end

  def owner_title
    mainline? ? project.title : owner.title
  end

  # returns the project if it's a KIND_PROJECT_REPO, otherwise the owner
  def project_or_owner
    project_repo? ? project : owner
  end

  def full_hashed_path
    hashed_path || set_repository_hash
  end

  # Returns a list of users being either the owner (if User) or each admin member (if Group)
  def owners
    result = if owned_by_group?
      owner.members.select do |member|
        owner.admin?(member)
      end
    else
      [owner]
    end
    return result
  end

  def set_repository_hash
    self.hashed_path ||= begin
      raw_hash = Digest::SHA1.hexdigest(owner.to_param +
                                        self.to_param +
                                        Time.now.to_f.to_s +
                                        ActiveSupport::SecureRandom.hex)
      sharded_hash = sharded_hashed_path(raw_hash)
      sharded_hash
    end
  end

  # Creates a block within which we generate events for each attribute changed
  # as long as it's changed to a legal value
  def log_changes_with_user(a_user)
    @updated_fields = []
    yield
    log_updates(a_user)
  end

  # Replaces a value within a log_changes_with_user block
  def replace_value(field, value, allow_blank = false)
    old_value = read_attribute(field)
    if !allow_blank && value.blank? || old_value == value
      return
    end
    self.send("#{field}=", value)
    valid?
    if !errors.on(field)
      @updated_fields << field
    end
  end

  # Logs events that occured within a log_changes_with_user block
  def log_updates(a_user)
    @updated_fields.each do |field_name|
      events.build(:action => Action::UPDATE_REPOSITORY, :user => a_user, :project => project, :body => "Changed the repository #{field_name.to_s}")
    end
  end

  def requires_signoff_on_merge_requests?
    mainline? && project.merge_requests_need_signoff?
  end

  def build_tracking_repository
    result = Repository.new(:parent => self, :user => user, :owner => owner, :kind => KIND_TRACKING_REPO, :name => "tracking_repository_for_#{id}", :project => project)
    return result
  end

  def create_tracking_repository
    result = build_tracking_repository
    result.save!
    return result
  end

  def tracking_repository
    self.class.find(:first, :conditions => {:parent_id => self, :kind => KIND_TRACKING_REPO})
  end

  def has_tracking_repository?
    !tracking_repository.nil?
  end

  def merge_request_status_tags
    # Note: we use 'as raw_status_tag' since the
    # MergeRequest#status_tag is overridden
    result = MergeRequest.find_by_sql(["SELECT status_tag as raw_status_tag
      FROM merge_requests
      WHERE target_repository_id = ?
      GROUP BY status_tag", self.id]).collect{|mr| mr.raw_status_tag }
    result.compact
  end

  # Fallback when the real sequence number is taken
  def calculate_highest_merge_request_sequence_number
    merge_requests.maximum(:sequence_number)
  end

  # The basis for the sequence number, reflects the number of merge requests
  def merge_request_count
    merge_requests.count
  end

  # Ideally we want to reflect how many merge requests are entered.
  # However, if this sequence is taken (an old record), we'll go one up
  # from the highest number instead
  def next_merge_request_sequence_number
    candidate = merge_request_count + 1
    if merge_requests.find_by_sequence_number(candidate)
      calculate_highest_merge_request_sequence_number + 1
    else
      candidate
    end
  end

  # Runs git-gc on this repository, and updates the last_gc_at attribute
  def gc!
    Grit::Git.with_timeout(nil) do
      if self.git.gc_auto
        self.last_gc_at = Time.now
        self.push_count_since_gc = 0
        return save
      end
    end
  end

  def register_push
    self.last_pushed_at = Time.now.utc
    self.push_count_since_gc = push_count_since_gc.to_i + 1
    update_disk_usage
  end

  def update_disk_usage
    self.disk_usage = calculate_disk_usage
  end

  def calculate_disk_usage
    @calculated_disk_usage ||= `du -sb #{full_repository_path} 2>/dev/null`.chomp.to_i
  end

  def matches_regexp?(term)
    return user.login =~ term ||
      name =~ term ||
      (owned_by_group? ? owner.name =~ term : false) ||
      description =~ term
  end

  def search_clones(term)
    self.class.title_search(term, "parent_id", id)
  end

  # Searches for term in
  # - title
  # - description
  # - owner name/login
  #
  # Scoped to column +key+ having +value+
  #
  # Example:
  #   title_search("foo", "parent_id", 1) #  will find clones of Repo with id 1
  #                                          matching 'foo'
  #
  #   title_search("foo", "project_id", 1) # will find repositories in Project#1
  #                                          matching 'foo'
  def self.title_search(term, key, value)
    sql = "SELECT repositories.* FROM repositories
      INNER JOIN users on repositories.user_id=users.id
      INNER JOIN groups on repositories.owner_id=groups.id
      WHERE repositories.#{key}=#{value}
      AND (repositories.name LIKE :q OR repositories.description LIKE :q OR groups.name LIKE :q)
      AND repositories.owner_type='Group'
      AND kind in (:kinds)
      UNION ALL
      SELECT repositories.* from repositories
      INNER JOIN users on repositories.user_id=users.id
      INNER JOIN users owners on repositories.owner_id=owners.id
      WHERE repositories.#{key}=#{value}
      AND (repositories.name LIKE :q OR repositories.description LIKE :q OR owners.login LIKE :q)
      AND repositories.owner_type='User'
      AND kind in (:kinds)"
    self.find_by_sql([sql, {:q => "%#{term}%",
                        :id => value,
                        :kinds =>
                        [KIND_TEAM_REPO, KIND_USER_REPO, KIND_PROJECT_REPO]}])
  end

  protected
    def sharded_hashed_path(h)
      first = h[0,3]
      second = h[3,3]
      last = h[-34, 34]
      "#{first}/#{second}/#{last}"
    end

    def create_initial_committership
      self.committerships.create_for_owner!(self.owner)
    end

    def self.full_path_from_partial_path(path)
      File.expand_path(File.join(GitoriousConfig["repository_base_path"], path))
    end

    def downcase_name
      name.downcase! if name
    end

    def create_add_event_if_project_repo
      if project_repo?
        #(action_id, target, user, data = nil, body = nil, date = Time.now.utc)
        self.project.create_event(Action::ADD_PROJECT_REPOSITORY, self, self.user,
              nil, nil, date = created_at)
      end
    end

    # Special permission check for KIND_WIKI repositories
    def wiki_writable_by?(a_user)
      case self.wiki_permissions
      when WIKI_WRITABLE_EVERYONE
        return true
      when WIKI_WRITABLE_PROJECT_MEMBERS
        return self.project.member?(a_user)
      end
    end

    def add_owner_as_watchers
      return if KINDS_INTERNAL_REPO.include?(self.kind)
      watched_by!(user)
    end

  private
  def self.create_hooks(path)
    hooks = File.join(GitoriousConfig["repository_base_path"], ".hooks")
    Dir.chdir(path) do
      hooks_base_path = File.expand_path("#{RAILS_ROOT}/data/hooks")

      if not File.symlink?(hooks)
        if not File.exist?(hooks)
          FileUtils.ln_s(hooks_base_path, hooks) # Create symlink
        end
      elsif File.expand_path(File.readlink(hooks)) != hooks_base_path
        FileUtils.ln_sf(hooks_base_path, hooks) # Fixup symlink
      end
    end

    local_hooks = File.join(path, "hooks")
    unless File.exist?(local_hooks)
      target_path = Pathname.new(hooks).relative_path_from(Pathname.new(path))
      Dir.chdir(path) do
        FileUtils.ln_s(target_path, "hooks")
      end
    end

    File.open(File.join(path, "description"), "w") do |file|
      sp = path.split("/")
      file << sp[sp.size-1, sp.size].join("/").sub(/\.git$/, "") << "\n"
    end
  end

end
