class Project < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to  :user
  has_many    :comments, :dependent => :destroy
  has_many    :repositories, :order => "repositories.mainline desc, repositories.created_at asc",
    :dependent => :destroy
  has_one     :mainline_repository, :conditions => ["mainline = ?", true], 
    :class_name => "Repository"
  has_many    :repository_clones, :conditions => ["mainline = ?", false],
    :class_name => "Repository"
  has_many    :events, :as => :target, :dependent => :destroy
    
  is_indexed :fields => ["title", "description", "slug"], 
    :concatenate => [
      { :class_name => 'Tag', 
        :field => 'name', 
        :as => 'category',
        :association_sql => "LEFT OUTER JOIN taggings ON taggings.taggable_id = projects.id " + 
                            "AND taggings.taggable_type = 'Project' LEFT OUTER JOIN tags ON taggings.tag_id = tags.id"
      }],
    :include => [{
      :association_name => "user",
      :field => "login",
      :as => "user"
    }]
      
    
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
    'GNU Lesser General Public License (LGPL)',
    'Mozilla Public License 1.0 (MPL)',
    'Mozilla Public License 1.1 (MPL 1.1)',
    'Qt Public License (QPL)',
    'Python License',
    'zlib/libpng License',
    'Apache Software License',
    'Apple Public Source License',
    'Perl Artistic License',
    'Microsoft Permissive License (Ms-PL)',
    'ISC License',
    'Lisp Lesser License',
    'Public Domain',
    'Other Open Source Initiative Approved License',
    'Other/Proprietary License',
    'None',
  ]
  
  def self.find_by_slug!(slug, opts = {})
    find_by_slug(slug, opts) || raise(ActiveRecord::RecordNotFound)
  end
  
  def self.per_page() 20 end
    
  def self.top_tags(limit = 10)
    tag_counts(:limit => limit, :order => "count desc")
  end
  
  def to_param
    slug
  end
  
  def admin?(candidate)
    candidate == user
  end
  
  def can_be_deleted_by?(candidate)
    (candidate == user) && (repositories.size == 1)
  end
  
  def tag_list=(tag_list)
    tag_list.gsub!(",", "")
    
    super
  end
  
  def stripped_description
    description.gsub(/<\/?[^>]*>/, "")
    # sanitizer = HTML::WhiteListSanitizer.new
    # sanitizer.sanitize(description, :tags => %w(str), :attributes => %w(class))
  end
  
  def to_xml(opts = {})
    info = Proc.new { |options|
      builder = options[:builder]
      builder.owner user.login
      
      builder.repositories :type => "array" do 
        repositories.each { |repo|
          builder.repository do
            builder.id repo.id
            builder.name repo.name
            builder.owner repo.user.login
          end
        }
      end
    }
    super({:procs => [info]}.merge(opts))
  end
  
  protected
    def create_mainline_repository
      self.repositories.create!(:user => self.user, :name => "mainline")
    end
    
    def downcase_slug
      slug.downcase! if slug
    end
  
end
