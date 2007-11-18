class Project < ActiveRecord::Base
  belongs_to :user
  has_many :repositories
  
  validates_presence_of :title, :user_id, :slug
  validates_format_of :slug, :with => /^[a-z0-9_\-]+$/, 
    :message => "Alphanumeric characters only"
  before_validation do |record|
    record.slug.downcase! if record.slug
  end
  
  def to_param
    slug
  end
end
