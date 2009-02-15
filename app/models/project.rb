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
  belongs_to  :owner, :polymorphic => true
  has_many    :comments, :dependent => :destroy
  
  has_many    :project_repositories, :order => "repositories.created_at asc",
      :conditions => ["kind = ?", Repository::KIND_PROJECT_REPO], 
      :class_name => "Repository"
  has_many  :repositories, :as => :owner, :conditions => { 
      :kind => Repository::KIND_PROJECT_REPO 
    }, :order => "repositories.created_at asc", :dependent => :destroy
  has_many    :events, :order => "created_at asc", :dependent => :destroy
  has_one     :wiki_repository, :class_name => "Repository", 
    :conditions => ["kind = ?", Repository::KIND_WIKI]  
  has_many  :groups
  
  attr_protected :owner_id, :user_id
  
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
  validates_presence_of :title, :user_id, :slug, :description, :owner_id
  validates_uniqueness_of :slug, :case_sensitive => false
  validates_format_of :slug, :with => /^#{NAME_FORMAT}$/i,
    :message => I18n.t( "project.format_slug_validation")
  validates_exclusion_of :slug, :in => Gitorious::Reservations.project_names
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
  
  def self.human_name
    I18n.t("activerecord.models.project")
  end

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
  
  def to_param_with_prefix
    to_param
  end

  def admin?(candidate)
    case owner
    when User
      candidate == self.owner
    when Group
      owner.admin?(candidate)
    end
  end
  
  def committer?(candidate)
    owner == User ? owner == candidate : owner.committer?(candidate)
  end
  
  def owned_by_group?
    owner === Group
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
  
  def change_owner_to(another_owner)
    unless owned_by_group?
      self.owner = another_owner
      self.wiki_repository.owner = another_owner
    end
  end

  protected    
    def create_wiki_repository
      self.wiki_repository = Repository.create!({
        :user => self.user, 
        :name => self.slug + Repository::WIKI_NAME_SUFFIX,
        :kind => Repository::KIND_WIKI,
        :project => self,
        :owner => self.owner,
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
