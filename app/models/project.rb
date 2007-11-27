class Project < ActiveRecord::Base
  belongs_to  :user
  has_many    :repositories, :order => "mainline desc, created_at desc"
  has_one     :mainline_repository, :conditions => ["mainline = ?", true], 
    :class_name => "Repository"
  has_many    :branch_repositories, :conditions => ["mainline = ?", false],
    :class_name => "Repository"
    
  URL_FORMAT_RE = /^(http|https|nntp):\/\//.freeze
  
  validates_presence_of :title, :user_id, :slug
  validates_format_of :slug, :with => /^[a-z0-9_\-]+$/i, 
    :message => "must match something in the range of [a-z0-9_\-]"
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
    'Public Domain',
    'Other/Proprietary License',
    'Microsoft Permissive License (Ms-PL)',
    'None',
  ]
  
  protected
    def create_mainline_repository
      self.repositories.create!(:user => self.user, :name => self.slug)
    end
    
    def downcase_slug
      slug.downcase! if slug
    end
  
end
