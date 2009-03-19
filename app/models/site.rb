class Site < ActiveRecord::Base
  has_many :projects
  
  validates_presence_of :title
  HTTP_CLONING_SUBDOMAIN = 'git'
  validates_exclusion_of :subdomain, :in => [HTTP_CLONING_SUBDOMAIN]
  
  attr_protected :subdomain
  
  def self.default
    new(:title => "Gitorious", :subdomain => nil)
  end
end
