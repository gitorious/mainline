class Project < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to  :user
  has_many    :comments, :dependent => :destroy
  has_many    :repositories, :order => "mainline desc, created_at asc",
    :dependent => :destroy
  has_one     :mainline_repository, :conditions => ["mainline = ?", true], 
    :class_name => "Repository"
  has_many    :repository_clones, :conditions => ["mainline = ?", false],
    :class_name => "Repository"
    
  URL_FORMAT_RE = /^(http|https|nntp):\/\//.freeze
  validates_presence_of :title, :user_id, :slug
  validates_uniqueness_of :slug, :case_sensitive => false
  validates_format_of :slug, :with => /^[a-z0-9_\-]+$/i, 
    :message => "must match something in the range of [a-z0-9_\-]+"
  validates_format_of :home_url, :with => URL_FORMAT_RE, 
    :if => proc{|record| !record.home_url.blank? },
    :message => "Must begin with http(s)"
  validates_format_of :mailinglist_url, :with => URL_FORMAT_RE,
    :if => proc{|record| !record.mailinglist_url.blank? },
    :message => "Must begin with http(s)"
  validates_format_of :bugtracker_url, :with => URL_FORMAT_RE, 
    :if => proc{|record| !record.bugtracker_url.blank? },
    :message => "Must begin with http(s)"
    
  before_validation :downcase_slug
  after_create :create_mainline_repository
  
  LICENSES = [
    'MIT License',
    'BSD License',
    'Ruby License',
    'GNU General Public License version 2(GPLv2)',
    'GNU General Public License version 3 (GPLv3)',
    'GNU Library Public License (LGPL)',
    'Mozilla Public License 1.0 (MPL)',
    'Mozilla Public License 1.1 (MPL 1.1)',
    'Qt Public License (QPL)',
    'Python License',
    'zlib/libpng License',
    'Apache Software License',
    'Apple Public Source License',
    'Perl Artistic License',
    'Public Domain',
    'Other/Proprietary License',
    'Microsoft Permissive License (Ms-PL)',
    'None',
  ]
  
  def self.find_by_slug!(slug)
    find_by_slug(slug) || raise(ActiveRecord::RecordNotFound)
  end
  
  def self.per_page() 20 end
  
  def to_param
    slug
  end
  
  def admin?(candidate)
    candidate == user
  end
  
  protected
    def create_mainline_repository
      self.repositories.create!(:user => self.user, :name => "mainline")
    end
    
    def downcase_slug
      slug.downcase! if slug
    end
  
end
