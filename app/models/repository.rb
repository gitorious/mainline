class Repository < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :project
  belongs_to  :parent, :class_name => "Repository"
  has_many    :committerships, :dependent => :destroy
  has_many    :committers, :through => :committerships, :source => :user
  has_many    :comments, :dependent => :destroy
  has_many    :merge_requests, :foreign_key => 'target_repository_id', :order => "status, id desc"
  has_many    :proposed_merge_requests, :foreign_key => 'source_repository_id', 
                :class_name => 'MergeRequest', :order => "id desc"
  
  validates_presence_of :user_id, :project_id, :name
  validates_format_of :name, :with => /^[a-z0-9_\-]+$/i,
    :message => "is invalid, must match something like /[a-z0-9_\\-]+/"
  validates_uniqueness_of :name, :scope => :project_id, :case_sensitive => false
  
  before_save :set_as_mainline_if_first
  after_create :add_user_as_committer, :create_new_repos_task
  after_destroy :create_delete_repos_task
  
  def self.new_by_cloning(other, username=nil)
    suggested_name = username ? "#{username}s-clone" : nil
    new(:parent => other, :project => other.project, :name => suggested_name)
  end
  
  def self.find_by_name!(name)
    find_by_name(name) || raise(ActiveRecord::RecordNotFound)
  end
  
  def self.create_git_repository(path)
    git_backend.create(full_path_from_partial_path(path))
  end
  
  def self.clone_git_repository(target_path, source_path)
    git_backend.clone(full_path_from_partial_path(target_path), 
      full_path_from_partial_path(source_path))
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
    "git@#{GitoriousConfig['gitorious_host']}:#{gitdir}"
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
  
  def to_xml
    super(:methods => [:gitdir, :clone_url, :push_url])
  end
  
  def add_committer(user)
    unless user.can_write_to?(self)
      committers << user
    end
  end
  
  def head_candidate
    return nil unless has_commits?
    @head_candidate ||= git.heads.find{|h| h.name == "master"} || git.heads.first
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
    
  protected
    def set_as_mainline_if_first
      unless project.repositories.size >= 1
        self.mainline = true
      end
    end
    
    def add_user_as_committer
      committers << user
    end
    
    def self.full_path_from_partial_path(path)
      File.expand_path(File.join(GitoriousConfig["repository_base_path"], path))
    end
end
