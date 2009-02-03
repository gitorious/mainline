#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class Project < ActiveRecord::Base
  acts_as_taggable

  belongs_to  :user
  has_many    :comments, :dependent => :destroy
  
  has_many    :project_repositories, :order => "repositories.created_at asc",
      :conditions => ["kind = ?", Repository::KIND_PROJECT_REPO], 
      :class_name => "Repository", :dependent => :destroy
  has_many  :repositories, :as => :owner, :conditions => { 
      :kind => Repository::KIND_PROJECT_REPO 
    }, :order => "repositories.created_at asc", :dependent => :destroy
  has_many    :events, :order => "created_at asc", :dependent => :destroy
  has_one     :wiki_repository, :class_name => "Repository", 
    :conditions => ["kind = ?", Repository::KIND_WIKI]
  
  has_one   :group, :conditions => { :public => false }
  has_many  :groups, :conditions => { :public => true }
  
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
  NAME_FORMAT = /[a-z0-9_\-]+/.freeze
  validates_presence_of :title, :user_id, :slug, :description
  validates_uniqueness_of :slug, :case_sensitive => false
  validates_format_of :slug, :with => /^#{NAME_FORMAT}$/i,
    :message => I18n.t( "project.format_slug_validation")
  validates_exclusion_of :slug, :in => Gitorious::Reservations::PROJECT_NAMES
  validates_format_of :home_url, :with => URL_FORMAT_RE,
    :if => proc{|record| !record.home_url.blank? },
    :message => I18n.t( "project.ssl_required")
  validates_format_of :mailinglist_url, :with => URL_FORMAT_RE,
    :if => proc{|record| !record.mailinglist_url.blank? },
    :message => I18n.t( "project.ssl_required")
  validates_format_of :bugtracker_url, :with => URL_FORMAT_RE,
    :if => proc{|record| !record.bugtracker_url.blank? },
    :message => I18n.t( "project.ssl_required")

  before_validation :downcase_slug
  before_create :create_core_group
  after_create :create_wiki_repository

  LICENSES = [
    'Academic Free License v3.0',
    'MIT License',
    'BSD License',
    'Ruby License',
    'GNU General Public License version 2(GPLv2)',
    'GNU General Public License version 3 (GPLv3)',
    'GNU Lesser General Public License (LGPL)',
    'GNU Affero General Public License (AGPLv3)',
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
    group.admin?(candidate)
  end

  def can_be_deleted_by?(candidate)
    (candidate == user) && (Repository.all_by_owner(self) - self.repositories).length == 0
  end

  def tag_list=(tag_list)
    tag_list.gsub!(",", "")
    super
  end

  def home_url=(url)
    self[:home_url] = clean_url(url)
  end

  def mailinglist_url=(url)
    self[:mailinglist_url] = clean_url(url)
  end

  def bugtracker_url=(url)
    self[:bugtracker_url] = clean_url(url)
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
  
  def create_event(action_id, target, user, data = nil, body = nil, date = Time.now.utc)
    events.create(:action => action_id, :target => target, :user => user,
                  :body => body, :data => data, :created_at => date)
  end
  
  def breadcrumb_parent
    nil
  end

  protected
    def create_core_group
      core_group = Group.create!(:name => self.slug + "-core")
      core_group.project = self
      core_group.creator = self.user
      core_group.public = false
      core_group.memberships.create!({
        :user => self.user,
        :role => Role.admin,
      })
      self.group = core_group
    end
    
    def create_wiki_repository
      self.wiki_repository = Repository.create!({
        :user => self.user, 
        :name => self.slug + Repository::WIKI_NAME_SUFFIX,
        :kind => Repository::KIND_WIKI,
        :project => self,
        :owner => self.group,
      })
    end

    def downcase_slug
      slug.downcase! if slug
    end

    # Try our best to guess the url
    def clean_url(url)
      return if url.blank?
      begin
        url = "http://#{url}" if URI.parse(url).class == URI::Generic
      rescue
      end
      url
    end
end
