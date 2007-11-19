class Project < ActiveRecord::Base
  belongs_to  :user
  has_many    :repositories
  has_one     :mainline_repository, :conditions => ["mainline = ?", true], 
    :class_name => "Repository"
  has_many    :branch_repositories, :conditions => ["mainline = ?", false],
    :class_name => "Repository"
  
  validates_presence_of :title, :user_id, :slug
  validates_format_of :slug, :with => /^[a-z0-9_\-]+$/, 
    :message => "Alphanumeric characters only"
  before_validation do |record|
    record.slug.downcase! if record.slug
  end
  
end
