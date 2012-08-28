
module GroupBehavior
  NAME_FORMAT = /[a-z0-9\-]+/.freeze

  def self.extended(klass)
    klass.belongs_to :creator, :class_name => "User", :foreign_key => "user_id"
    klass.has_many(:repositories, :as => :owner, :conditions => ["kind NOT IN (?)",
                                                                 Repository::KINDS_INTERNAL_REPO],
      :dependent => :destroy)
    klass.has_many(:cloneable_repositories, :as => :owner, :class_name => "Repository",
      :conditions => ["kind != ?", Repository::KIND_TRACKING_REPO])
    klass.has_many(:projects, :as => :owner)
    klass.validates_presence_of(:name)
    klass.validates_uniqueness_of(:name)
    klass.validates_format_of(:name, :with => /^#{NAME_FORMAT}$/,
      :message => "Must be alphanumeric, and optional dash")

    klass.before_validation :downcase_name
    klass.has_many :committerships, :as => :committer, :dependent => :destroy
    klass.has_many :participated_repositories, :through => :committerships,
    :source => :repository, :class_name => 'Repository'
    klass.has_many :content_memberships, :as => :member, :dependent => :destroy


    def klass.find_fuzzy(query)
      find(:all,
        :conditions => ["LOWER(name) LIKE ?", "%" + query.downcase + "%"],
        :limit => 10)
    end
  end


  module InstanceMethods
    def to_param_with_prefix
      "+#{to_param}"
    end
    
    def downcase_name
      name.downcase! if name
    end
  end
end
