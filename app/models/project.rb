class Project < ActiveRecord::Base
  belongs_to :user
  has_many :repositories
  
  validates_presence_of :title
end
