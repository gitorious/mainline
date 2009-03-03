class Site < ActiveRecord::Base
  has_many :projects
  
  validates_presence_of :title
  
  def self.default
    new(:title => "Gitorious", :subdomain => nil)
  end
end
