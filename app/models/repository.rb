# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 David Aguilar <davvid@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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
require "gitorious"
require "gitorious/messaging"

class Repository < ActiveRecord::Base
  include Gitorious::Messaging::Publisher
  include Watchable
  include Gitorious::Authorization
  include Gitorious::Protectable

  KIND_PROJECT_REPO = 0
  KIND_WIKI = 1
  KIND_TEAM_REPO = 2
  KIND_USER_REPO = 3
  KIND_TRACKING_REPO = 4
  KINDS_INTERNAL_REPO = [KIND_WIKI, KIND_TRACKING_REPO]

  belongs_to  :user
  belongs_to  :project
  belongs_to  :owner, :polymorphic => true
  has_many    :repository_memberships, :as => :content
  has_many    :content_memberships, :as => :content
  belongs_to  :parent, :class_name => "Repository"
  has_many    :clones, :class_name => "Repository", :foreign_key => "parent_id",
    :dependent => :nullify
  has_many    :comments, :as => :target, :dependent => :destroy
  has_many    :merge_requests, :foreign_key => "target_repository_id",
    :order => "status, id desc", :dependent => :destroy
  has_many    :proposed_merge_requests, :foreign_key => "source_repository_id",
                :class_name => "MergeRequest", :order => "id desc", :dependent => :destroy
  has_many    :cloners, :dependent => :destroy
  has_many    :events, :as => :target, :dependent => :destroy
  has_many    :services, :dependent => :destroy

  has_many    :_committerships, :dependent => :destroy

  def committerships
    RepositoryCommitterships.new(self)
  end

  after_destroy :post_repo_deletion_message

  scope :by_users,  :conditions => { :kind => KIND_USER_REPO } do
    def fresh(limit = 10)
      order("last_pushed_at DESC").limit(limit)
    end
  end

  scope :by_groups, :conditions => { :kind => KIND_TEAM_REPO } do
    def fresh(limit=10)
      order("last_pushed_at DESC").limit(limit)
    end
  end

  scope :clones,    :conditions => ["kind in (?) and parent_id is not null",
                                          [KIND_TEAM_REPO, KIND_USER_REPO]]

  scope :mainlines, :conditions => { :kind => KIND_PROJECT_REPO }

  scope :regular, :conditions => ["kind in (?)", [KIND_TEAM_REPO, KIND_USER_REPO,
                                                       KIND_PROJECT_REPO]]

  def open_merge_requests
    # merge_requests.open doesn't quite work, presumably related to the
    # issue of 'open': Object#open, "open" state and "open" scope. Overload!
    # TODO: Refactor MergeRequest
    merge_requests.where({}).open
  end

  def destroy
    merge_requests.each &:destroy
    reload
    super
  end

  def self.human_name
    I18n.t("activerecord.models.repository")
  end

  def self.find_by_name_in_project!(name, containing_project = nil)
    if containing_project
      find_by_name_and_project_id!(name, containing_project.id)
    else
      find_by_name!(name)
    end
  end

  def self.find_by_path(path)
    base_path = path.gsub(/^#{Regexp.escape(RepositoryRoot.default_base_path)}/, "")
    path_components = base_path.split("/").reject{|p| p.blank? }
    repo_name, owner_name = [path_components.pop, path_components.shift]
    project_name = path_components.pop
    repo_name.sub!(/\.git/, "")

    raise ActiveRecord::RecordNotFound unless owner_name

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
    Repository.where({ :name => repo_name }.merge(owner_conditions)).first
  end

  def self.delete_git_repository(path)
    git_backend.delete!(RepositoryRoot.expand(path).to_s)
  end

  def self.most_active_clones_in_projects(projects, limit = 5)
    key = "repository:most_active_clones_in_projects:#{projects.map(&:id).join('-')}:#{limit}"
    clone_ids = projects.map do |project|
      project.repositories.clones.map{|r| r.id }
    end.flatten

    select("distinct repositories.*, count(events.id) as event_count").
      where("repositories.id in (?) and events.created_at > ? and kind in (?)",
            clone_ids, 7.days.ago,
            [KIND_USER_REPO, KIND_TEAM_REPO]).
      order("count(events.id) desc").
      joins(:events).
      includes(:project).
      group("repositories.id").
      limit(limit)
  end

  def self.most_active_clones(limit = 10)
    select("distinct repositories.id, repositories.*, count(events.id) as event_count").
      where("events.created_at > ? and kind in (?)",
            7.days.ago,
            [KIND_USER_REPO, KIND_TEAM_REPO]).
      order("count(events.id) desc").
      group("repositories.id").
      joins(:events).
      includes(:project).
      limit(limit)
  end

  # Finds all repositories that might be due for a gc, starting with
  # the ones who've been pushed to recently
  def self.all_due_for_gc(batch_size = 25)
    where("push_count_since_gc > 0").
      order("push_count_since_gc desc").
      limit(batch_size)
  end

  def gitdir
    "#{url_path}.git"
  end

  # The project/repo path segment is useful for more things than URLs
  def path_segment
    File.join(project.to_param_with_prefix, name)
  end

  def url_path
    path_segment
  end

  def real_gitdir
    "#{self.full_hashed_path}.git"
  end

  def browse_url
    Gitorious.url(url_path)
  end

  def default_clone_protocol
    return "git" if git_cloning?
    return "http" if http_cloning?
    "ssh"
  end

  def default_clone_url
    send(:"#{default_clone_protocol}_clone_url")
  end

  def clone_url
    if http_cloning?
      http_clone_url
    elsif ssh_cloning?
      ssh_clone_url
    else
      raise "cloning disabled"
    end
  end

  def ssh_clone_url
    Gitorious.ssh_daemon.url(gitdir)
  end

  def git_clone_url
    Gitorious.git_daemon.url(gitdir)
  end

  def http_clone_url
    Gitorious.git_http.url(gitdir)
  end

  def http_cloning?
    !Gitorious.git_http.nil?
  end

  def git_cloning?
    return !Gitorious.git_daemon.nil? && public?
  end

  def ssh_cloning?
    return !Gitorious.ssh_daemon.nil?
  end

  def push_url
    if ssh_cloning?
      ssh_clone_url
    elsif http_cloning?
      http_clone_url
    else
      raise "pushing disabled"
    end
  end

  def display_ssh_url?(user)
    return true if !http_cloning? && !git_cloning? && ssh_cloning?
    can_push?(user, self)
  end

  def full_repository_path
    RepositoryRoot.expand(real_gitdir).to_s
  end

  def git
    Grit::Repo.new(full_repository_path)
  end

  def has_commits?
    return false if new_record? || !ready?
    !git.heads.empty?
  end

  def self.git_backend
    Rails.env.test? ? MockGitBackend : GitBackend
  end

  def git_backend
    Rails.env.test? ? MockGitBackend : GitBackend
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
    return head.name if head = head_candidate
    "master"
  end

  def head
    git && git.head
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

  # changes the owner to +another_owner+, removes the old owner as committer
  # and adds +another_owner+ as committer
  def change_owner_to!(another_owner)
    return if owned_by_group?

    transaction do
      committerships.destroy_for_owner
      self.owner = another_owner
      if self.kind != KIND_PROJECT_REPO # project_repo?
        case another_owner
        when Group
          self.kind = KIND_TEAM_REPO
        when User
          self.kind = KIND_USER_REPO
        end
      end
      committerships.update_owner(another_owner)
      save!
      reload
    end
  end

  def post_repo_deletion_message
    payload = {
      :target_class => self.class.name,
      :command => "delete_git_repository",
      :arguments => [real_gitdir]
    }

    publish("/queue/GitoriousRepositoryDeletion", payload)
  end

  def total_commit_count
    events.count(:conditions => {:action => Action::COMMIT})
  end

  def git_derived_total_commit_count(ref)
    begin
      total = git.commit_count(ref)
    rescue Grit::Git::GitTimeout
      total = 2046
    end
  end

  def paginated_commits(ref, page, per_page = 30)
    page    = (page || 1).to_i
    total = git_derived_total_commit_count(ref)
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

    User.where("email in (?)", emails.keys).each do |user|
      author_name = emails[user.email]
      if h[author_name] # in the event that a user with the same name has used two different emails, he'd be gone by now
        h[user.login] = h.delete(author_name)
      end
    end

    h
  end

  # Returns a Hash {email => user}, where email is selected from the +commits+
  def self.users_by_commits(commits)
    emails = commits.map { |commit| commit.author.email }.uniq
    users = User.where("email in (?)", emails)

    users_by_email = users.inject({}){|hash, user| hash[user.email] = user; hash }
    users_by_email
  end

  def cloned_from(ip, country_code = "--", country_name = nil, protocol = "git")
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

  def owned_by_group?
    owner.is_a?(Group) || owner.is_a?(LdapGroup)
  end

  def internal?
    wiki? || tracking_repo?
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

  # Returns a list of users being either the owner (if User) or each admin member (if Group)
  def owners
    result = if owned_by_group?
      owner.members.select do |member|
        if owner.respond_to?(:admin)
          admin?(member, owner)
        else
          admin?(member, owner)
        end
      end
    else
      [owner]
    end
    return result
  end

  def full_hashed_path
    self.hashed_path || set_repository_path
  end

  def set_repository_path
    if RepositoryRoot.shard_dirs?
      set_repository_hash
    else
      set_repository_plain_path
    end
  end

  def set_repository_plain_path
    self.hashed_path ||= repository_plain_path
  end

  def repository_plain_path
    if project
      "#{self.project.slug}/#{self.name}"
    else
      "#{self.name}"
    end
  end

  alias_method :slug, :repository_plain_path

  def set_repository_hash
    self.hashed_path ||= begin
      raw_hash = Digest::SHA1.hexdigest(owner.to_param +
                                        self.to_param +
                                        Time.now.to_f.to_s +
                                        SecureRandom.hex)
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
    return if !allow_blank && value.blank? || old_value == value
    self.send("#{field}=", value)
    validation = RepositoryValidator.call(self)

    if validation.errors[field].length == 0
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

  def tracking_repository
    self.class.where(:parent_id => self, :kind => KIND_TRACKING_REPO).first
  end

  def has_tracking_repository?
    !tracking_repository.nil?
  end

  def next_merge_request_sequence_number
    last_merge_request_sequence_number + 1
  end

  # Runs git-gc on this repository, and updates the last_gc_at attribute
  def gc!
    Grit::Git.with_timeout(nil) do
      if self.git.git.gc
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
      WHERE repositories.#{key}=:id
      AND (repositories.name LIKE :q OR repositories.description LIKE :q OR groups.name LIKE :q)
      AND repositories.owner_type='Group'
      AND kind in (:kinds)
      UNION ALL
      SELECT repositories.* from repositories
      INNER JOIN users on repositories.user_id=users.id
      INNER JOIN users owners on repositories.owner_id=owners.id
      WHERE repositories.#{key}=:id
      AND (repositories.name LIKE :q OR repositories.description LIKE :q OR owners.login LIKE :q)
      AND repositories.owner_type='User'
      AND kind in (:kinds)"
    self.find_by_sql([sql, {:q => "%#{term}%",
                        :id => value,
                        :kinds =>
                        [KIND_TEAM_REPO, KIND_USER_REPO, KIND_PROJECT_REPO]}])
  end

  alias :repo_public? :public?

  def public?
    repo_public? && project.public?
  end

  def self.private_on_create?(params = {})
    return false if !Gitorious.private_repositories?
    params.fetch(:private, Gitorious.repositories_default_private?)
  end

  def uniq_name?
    repository = Repository.where("lower(name) = ? and project_id = ?", name, project_id).first
    repository.nil? || repository == self
  end

  def uniq_hashed_path?
    repository = Repository.where("lower(hashed_path) = ?", hashed_path).first
    repository.nil? || repository == self
  end

  def name=(name)
    self[:name] = name.respond_to?(:downcase) ? name.downcase : name
  end

  def kind=(kind)
    if kind == :project
      self[:kind] = Repository::KIND_PROJECT_REPO
    elsif kind == :tracking
      self[:kind] = Repository::KIND_TRACKING_REPO
    elsif kind == :wiki
      self[:kind] = Repository::KIND_WIKI
    elsif kind == :user
      self[:kind] = Repository::KIND_USER_REPO
    elsif kind == :team
      self[:kind] = Repository::KIND_TEAM_REPO
    else
      self[:kind] = kind
    end
  end

  def commit_comments(id)
    comments.where(:sha1 => id).includes(:user)
  end

  protected
  def sharded_hashed_path(h)
    first = h[0,3]
    second = h[3,3]
    last = h[-34, 34]
    "#{first}/#{second}/#{last}"
  end

  def self.reserved_names
    @reserved_names ||= []
  end

  def self.reserve_names(names)
    @reserved_names ||= []
    @reserved_names.concat(names)
  end
end
