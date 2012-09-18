class ProjectProposal < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "user_id"
  validates_presence_of :title, :user_id, :description
  validates_uniqueness_of :title
  has_many :messages, :as => :notifiable
  def name_clashes_with_existing_project?
    !Project.find_by_title(self.title).nil?
  end

  def reject
    self.destroy
  end
  
  def approve
    project = Project.new({
                :title => self.title,
                :slug => self.title.gsub(" ", "-"),
                :description => self.description,
                :user => self.creator,
                :owner => self.creator
              })
    project.save!
    self.destroy
    return project
  end
end
