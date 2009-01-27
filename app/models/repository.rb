#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 David Aguilar <davvid@gmail.com>
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

class Repository < ActiveRecord::Base
  
  KIND_PROJECT_REPO = 0
  KIND_WIKI = 1
  WIKI_NAME_SUFFIX = "-gitorious-wiki"
  
  belongs_to  :user # TODO: rename to creator..
  belongs_to  :project
  belongs_to  :owner, :polymorphic => true
  belongs_to  :parent, :class_name => "Repository"
  has_many    :comments, :dependent => :destroy
  has_many    :merge_requests, :foreign_key => 'target_repository_id', 
    :order => "status, id desc", :dependent => :destroy
  has_many    :proposed_merge_requests, :foreign_key => 'source_repository_id', 
                :class_name => 'MergeRequest', :order => "id desc", :dependent => :destroy
  has_many    :cloners, :dependent => :destroy
  has_many    :events, :as => :target, :dependent => :destroy
  
  validates_presence_of :user_id, :project_id, :name, :owner_id
  validates_format_of :name, :with => /^[a-z0-9_\-]+$/i,
    :message => "is invalid, must match something like /[a-z0-9_\\-]+/"
  validates_uniqueness_of :name, :scope => :project_id, :case_sensitive => false
  
  before_save   :set_as_mainline_if_first
  after_create  :create_new_repos_task
  after_destroy :create_delete_repos_task
  
  def self.new_by_cloning(other, username=nil)
    suggested_name = username ? "#{username}-clone" : nil
    new(:parent => other, :project => other.project, :name => suggested_name)
  end
  
  def self.find_by_name!(name)
    find_by_name(name) || raise(ActiveRecord::RecordNotFound)
  end
  
  def self.find_by_path(path)
    base_path = path.gsub(/^#{Regexp.escape(GitoriousConfig['repository_base_path'])}/, "")
    repo_name, project_name = base_path.split("/").reverse
    
    project = Project.find_by_slug!(project_name)
    Repository.find_by_name_and_project_id(repo_name.sub(/\.git/, ""), project.id)
  end
  
  def self.create_git_repository(path)
    full_path = full_path_from_partial_path(path)
    git_backend.create(full_path)
    
    self.create_hooks(full_path)
  end
  
  def self.clone_git_repository(target_path, source_path)
    full_path = full_path_from_partial_path(target_path)
    git_backend.clone(full_path, 
      full_path_from_partial_path(source_path))
      
    self.create_hooks(full_path)
  end
  
  def self.delete_git_repository(path)
    git_backend.delete!(full_path_from_partial_path(path))
  end
  
  def gitdir
    File.join(project.slug, "#{name}.git")
  end
  
  def clone_url
    "git://#{GitoriousConfig['gitorious_host']}/#{gitdir}"
  end
  
  def http_clone_url
    "http://git.#{GitoriousConfig['gitorious_host']}/#{gitdir}"
  end
  
  def push_url
    "#{GitoriousConfig['gitorious_user']}@#{GitoriousConfig['gitorious_host']}:#{gitdir}"
  end
  
  def full_repository_path
    self.class.full_path_from_partial_path(gitdir)
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
    super({:methods => [:gitdir, :clone_url, :push_url]}.merge(opts))
  end
  
  def head_candidate
    return nil unless has_commits?
    @head_candidate ||= git.heads.find{|h| h.name == "master"} || git.heads.first
  end
  
  def head_candidate_name
    if head = head_candidate
      head.name.include?("/") ? head.commit.id : head.name
    end
  end
  
  def last_commit
    if has_commits?
      @last_commit ||= git.commits(head_candidate.name, 1).first
    end
    @last_commit
  end
  
  def can_be_deleted_by?(candidate)
    !mainline? && (candidate == user)
  end
  
  def writable_by?(a_user)
    case owner
    when User
      self.owner == a_user
    when Group
      self.owner.committer?(a_user)
    else
      user == a_user
    end
  end
  
  def create_new_repos_task
    Task.create!(:target_class => self.class.name, 
      :command => parent ? "clone_git_repository" : "create_git_repository", 
      :arguments => parent ? [gitdir, parent.gitdir] : [gitdir], 
      :target_id => self.id)
  end
  
  def create_delete_repos_task
    Task.create!(:target_class => self.class.name, 
      :command => "delete_git_repository", :arguments => [gitdir])
  end
  
  def total_commit_count
    events.count(:conditions => {:action => Action::COMMIT})
  end
  
  def paginated_commits(tree_name, page, per_page = 30)
    page    = (page || 1).to_i
    begin
      total   = git.commit_count(tree_name)
    rescue Grit::Git::GitTimeout
      total = 2046
    end
    offset  = (page - 1) * per_page
    commits = WillPaginate::Collection.new(page, per_page, total)
    commits.replace git.commits(tree_name, per_page, offset)
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
  
  
  def cloned_from(ip, country_code = "--", country_name = nil)
    cloners.create(:ip => ip, :date => Time.now.utc, :country_code => country_code, :country => country_name)
  end
  
  def wiki?
    kind == KIND_WIKI
  end
  
  def project_repo?
    kind == KIND_PROJECT_REPO
  end
  
  def committers
    owner === Group ? owner.members : [owner]
  end
  
  def owned_by_group?
    owner === Group
  end
  
  protected
    def set_as_mainline_if_first
      unless project.repositories.size >= 1
        self.mainline = true
      end
    end
    
    def self.full_path_from_partial_path(path)
      File.expand_path(File.join(GitoriousConfig["repository_base_path"], path))
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
