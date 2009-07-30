# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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
  include RecordThrottling
  include UrlLinting

  belongs_to  :user
  belongs_to  :owner, :polymorphic => true
  has_many    :comments, :dependent => :destroy
  
  has_many    :repositories, :order => "repositories.created_at asc", 
      :conditions => ["kind != ?", Repository::KIND_WIKI], :dependent => :destroy
  has_one     :wiki_repository, :class_name => "Repository", 
    :conditions => ["kind = ?", Repository::KIND_WIKI], :dependent => :destroy
  has_many    :events, :order => "created_at asc", :dependent => :destroy
  has_many    :groups
  belongs_to  :containing_site, :class_name => "Site", :foreign_key => "site_id"
  has_many    :merge_request_statuses, :order => "id asc"
  accepts_nested_attributes_for :merge_request_statuses, :allow_destroy => true
  
  serialize :merge_request_custom_states, Array
  
  attr_protected :owner_id, :user_id, :site_id
  
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
  after_create :create_default_merge_request_statuses
  
  throttle_records :create, :limit => 5,
    :counter => proc{|record|
      record.user.projects.count(:all, :conditions => ["created_at > ?", 5.minutes.ago])
    },
    :conditions => proc{|record| {:user_id => record.user.id} },
    :timeframe => 5.minutes

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
    'Apache License',
    'Apple Public Source License',
    'Perl Artistic License',
    'Microsoft Permissive License (Ms-PL)',
    'ISC License',
    'Lisp Lesser License',
    'Public Domain',
    'Other Open Source Initiative Approved License',
    'Other/Proprietary License',
    'Other/Multiple',
    'None',
  ]
  
  def self.human_name
    I18n.t("activerecord.models.project")
  end

  def self.per_page() 20 end

  def self.top_tags(limit = 10)
    tag_counts(:limit => limit, :order => "count desc")
  end
  
  # Returns the projects limited by +limit+ who has the most activity within
  # the +cutoff+ period
  def self.most_active_recently(limit = 10, cutoff = 3.days.ago)
    Rails.cache.fetch("projects:most_active_recently:#{limit}:#{cutoff.to_i}", :expires_in => 30.minutes) do
      find(:all, :joins => :events, :limit => limit,
        :select => 'distinct projects.*, count(events.id) as event_count', 
        :order => "event_count desc", :group => "projects.id",
        :conditions => ["events.created_at > ?", cutoff])
    end
  end
  
  # Finds the most active projects on an overall basis
  def self.most_active_overall(limit = 10)
    Rails.cache.fetch("projects:most_active_overall:#{limit}", :expires_in => 30.minutes) do
      find(:all, :joins => :events, :limit => limit,
        :select => 'distinct projects.*, count(events.id) as event_count', 
        :order => "event_count desc", :group => "projects.id")
    end
  end

  def to_param
    slug
  end
  
  def to_param_with_prefix
    to_param
  end
  
  def site
    containing_site || Site.default
  end

  def admin?(candidate)
    case owner
    when User
      candidate == self.owner
    when Group
      owner.admin?(candidate)
    end
  end
  
  def member?(candidate)
    case owner
    when User
      candidate == self.owner
    when Group
      owner.member?(candidate)
    end
  end
  
  def committer?(candidate)
    owner == User ? owner == candidate : owner.committer?(candidate)
  end
  
  def owned_by_group?
    owner === Group
  end

  def can_be_deleted_by?(candidate)
    admin?(candidate) && repositories.clones.count == 0
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
  
  def descriptions_first_paragraph
    description[/^([^\n]+)/, 1]
  end

  def to_xml(opts = {})
    info = Proc.new { |options|
      builder = options[:builder]
      builder.owner(owner.to_param, :kind => (owned_by_group? ? "Team" : "User"))
      
      builder.repositories(:type => "array") do |repos|
        builder.mainlines :type => "array" do
          repositories.mainlines.each { |repo|
            builder.repository do
              builder.id repo.id
              builder.name repo.name
              builder.owner repo.owner.to_param, :kind => (repo.owned_by_group? ? "Team" : "User")
              builder.clone_url repo.clone_url
            end
          }
        end
        builder.clones :type => "array" do
          repositories.clones.each { |repo|
            builder.repository do
              builder.id repo.id
              builder.name repo.name
              builder.owner repo.owner.to_param, :kind => (repo.owned_by_group? ? "Team" : "User")
              builder.clone_url repo.clone_url
            end
          }
        end
      end
    }
    super({
      :procs => [info],
      :only => [:slug, :title, :description, :license, :home_url, :wiki_enabled,
                :created_at, :bugtracker_url, :mailinglist_url, :bugtracker_url],
    }.merge(opts))
  end
  
  def create_event(action_id, target, user, data = nil, body = nil, date = Time.now.utc)
    events.create(:action => action_id, :target => target, :user => user,
                  :body => body, :data => data, :created_at => date)
  end
  
  def new_event_required?(action_id, target, user, data)
    events_count = events.count(:all, :conditions => [
      "action = :action_id AND target_id = :target_id AND target_type = :target_type AND user_id = :user_id and data = :data AND created_at > :date_threshold",
      {
        :action_id => action_id, 
        :target_id => target.id, 
        :target_type => target.class.name, 
        :user_id => user.id, 
        :data => data, 
        :date_threshold => 1.hour.ago
      }])
    return events_count < 1
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
  
  # TODO: Add tests
  def oauth_consumer
    case Rails.env
    when "test"
      @oauth_consumer ||= OAuth::TestConsumer.new
    else
      @oauth_consumer ||= OAuth::Consumer.new(oauth_signoff_key, oauth_signoff_secret, oauth_consumer_options)
    end
  end
  
  def oauth_consumer_options
    result = {:site => oauth_signoff_site}
    unless oauth_path_prefix.blank?
      %w(request_token authorize access_token).each do |p|
        result[:"#{p}_path"] = File.join("/", oauth_path_prefix, p)
      end
    end
    result
  end
  
  def oauth_settings=(options)
    self.merge_requests_need_signoff = !options[:site].blank?
    self.oauth_path_prefix    = options[:path_prefix]
    self.oauth_signoff_key    = options[:signoff_key]
    self.oauth_signoff_secret = options[:signoff_secret]
    self.oauth_signoff_site   = options[:site]
  end
  
  def oauth_settings
    {
      :path_prefix    => oauth_path_prefix,
      :signoff_key    => oauth_signoff_key,
      :site           => oauth_signoff_site,
      :signoff_secret => oauth_signoff_secret
    }
  end
  
  
  def wiki_permissions
    wiki_repository.wiki_permissions
  end
  
  def wiki_permissions=(perms)
    wiki_repository.wiki_permissions = perms
  end

  # Returns an array of merge request states
  def merge_request_state_list
    if merge_request_statuses.blank?
      MergeRequestStatus.create_defaults_for_project(self)
    end
    merge_request_statuses.map do |status|
      status.name
    end      
  end
  
  # Returns a String representation of the merge request states
  def merge_request_states
    (merge_request_custom_states || merge_request_default_states).join("\n")
  end

  def merge_request_states=(s)
    self.merge_request_custom_states = s.split("\n").collect(&:strip)
  end
  

  def merge_request_fixed_states
    ['Merged','Rejected']
  end
  
  def merge_request_default_states
    ['Open','Closed','Verifying']
  end

  def has_custom_merge_request_states?
    !merge_request_custom_states.blank?
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

    def create_default_merge_request_statuses
      MergeRequestStatus.create_defaults_for_project(self)
    end

    def downcase_slug
      slug.downcase! if slug
    end
end
