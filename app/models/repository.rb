class Repository < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :project
  has_many    :permissions
  has_many    :committers, :through => :permissions, :source => :user, :dependent => :destroy
  
  validates_presence_of :user_id, :project_id, :name
  validates_format_of :name, :with => /^[a-z0-9_\-]+$/i
  
  before_save :set_as_mainline_if_first
  after_create :add_user_as_committer, :create_git_repository
  
  BASE_REPOSITORY_URL = "keysersource.org"
  BASE_PATH = (RAILS_ENV == "test" ? "../test_repositories" : "../repositories")
  BASE_REPOSITORY_DIR = File.join(RAILS_ROOT, BASE_PATH)
  
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
    FileUtils.mkdir(full_repository_path, :mode => 0750)
    Dir.chdir(full_repository_path) do |path| 
      Git.init(path, :repository => path)
    end
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
