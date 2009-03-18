class Site < ActiveRecord::Base
  has_many :projects
  
  validates_presence_of :title
  validates_exclusion_of :subdomain, :in => ['http']
  
  attr_protected :subdomain
  
  def self.default
    new(:title => "Gitorious", :subdomain => nil)
  end
end
