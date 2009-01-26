class Role < ActiveRecord::Base
  KIND_ADMIN = 0
  KIND_COMMITTER = 1
  
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
