class Repository < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  
  validates_presence_of :user_id, :project_id, :name
  validates_format_of :name, :with => /^[a-z0-9_\-]+$/i
  
  before_save :set_as_mainline_if_first
  
  BASE_REPOSITORY_URL = "keysersource.org"
  
  def url
    "git@#{BASE_REPOSITORY_URL}:#{name}.git"
  end
    
  protected
    def set_as_mainline_if_first
      unless project.repositories.size >= 1
        self.mainline = true
      end
    end
end
