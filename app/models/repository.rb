class Repository < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :project
  has_many    :permissions, :dependent => :destroy
  has_many    :committers, :through => :permissions, :source => :user
  
  validates_presence_of :user_id, :project_id, :name
  validates_format_of :name, :with => /^[a-z0-9_\-]+$/i
  
  before_save :set_as_mainline_if_first
  after_create :add_user_as_committer, :create_git_repository
  
  BASE_REPOSITORY_URL = "keysersource.org"
  BASE_REPOSITORY_DIR = File.join(RAILS_ROOT, "../repositories")
  
  def gitdir
    "#{name}.git"
  end
  
  def clone_url
    "git://#{BASE_REPOSITORY_URL}/#{gitdir}"
  end
  
  def push_url
    "git@#{BASE_REPOSITORY_URL}:#{gitdir}"
  end
  
  def full_repository_path
    #File.expand_path(File.join(BASE_REPOSITORY_DIR, project.slug, gitdir))
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
