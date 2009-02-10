class Role < ActiveRecord::Base
  KIND_ADMIN = 0
  KIND_COMMITTER = 1
  
  # TODO: use this when we upgrade to rails 2.3, and nuke the ::all override
  # default_scope :order => 'kind desc'
  
  def self.all
    find(:all, :order => 'kind desc')
  end
  
  def self.admin
    find_by_kind(KIND_ADMIN)
  end
  
  def self.committer
    find_by_kind(KIND_COMMITTER)
  end
  
  def admin?
    kind == KIND_ADMIN
  end
  
  def committer?
    kind == KIND_COMMITTER
  end  
end
