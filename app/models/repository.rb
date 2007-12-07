class Repository < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :project
  belongs_to  :parent, :class_name => "Repository"
  has_many    :permissions, :dependent => :destroy
  has_many    :committers, :through => :permissions, :source => :user
  
  validates_presence_of :user_id, :project_id, :name
  validates_format_of :name, :with => /^[a-z0-9_\-]+$/i
  validates_uniqueness_of :name, :scope => :project_id, :case_sensitive => false
  
  before_save :set_as_mainline_if_first
  after_create :add_user_as_committer, :create_git_repository
  
  def self.new_by_cloning(other)
    new(:parent => other, :project => other.project)
  end
  
  BASE_REPOSITORY_URL = "keysersource.org"
  BASE_REPOSITORY_DIR = File.join(RAILS_ROOT, "../repositories")
  
  def gitdir
    File.join(project.slug, "#{name}.git")
  end
  
  def clone_url
    "git://#{BASE_REPOSITORY_URL}/#{gitdir}"
  end
  
  def push_url
    "git@#{BASE_REPOSITORY_URL}:#{gitdir}"
  end
  
  def full_repository_path
    File.expand_path(File.join(BASE_REPOSITORY_DIR, gitdir))
  end
  
  def create_git_repository
    git_backend.create(full_repository_path)
  end
  
  def has_commits?
    git_backend.repository_has_commits?(full_repository_path)
  end
  
  def git_backend
    RAILS_ENV == "test" ? MockGitBackend : GitBackend
  end
  
  def readify
    self.ready = true    
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
end
