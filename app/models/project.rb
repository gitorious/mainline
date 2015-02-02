# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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
  include UrlLinting
  include Watchable
  include Gitorious::Authorization
  include Gitorious::Protectable

  belongs_to  :user
  belongs_to  :owner, :polymorphic => true
  has_many    :comments, :dependent => :destroy
  has_many    :project_memberships, :as => :content
  has_many    :content_memberships, :as => :content
  has_many    :repositories, :order => "repositories.created_at asc",
      :conditions => ["kind != ?", Repository::KIND_WIKI], :dependent => :destroy
  has_one     :wiki_repository, :class_name => "Repository",
    :conditions => ["kind = ?", Repository::KIND_WIKI], :dependent => :destroy
  has_many :cloneable_repositories, :class_name => "Repository",
     :conditions => ["kind != ?", Repository::KIND_TRACKING_REPO]
  has_many    :events, :order => "created_at desc", :dependent => :destroy
  has_many    :groups
  belongs_to  :containing_site, :class_name => "Site", :foreign_key => "site_id"
  has_many    :merge_request_statuses, :order => "id asc", :dependent => :destroy
  accepts_nested_attributes_for :merge_request_statuses, :allow_destroy => true

  default_scope :conditions => ["projects.suspended_at is null"]
  serialize :merge_request_custom_states, Array
  attr_accessible(:title, :description, :user, :slug, :license,
    :home_url, :mailinglist_url, :bugtracker_url, :owner, :wiki_enabled,
    :owner_type, :tag_list, :merge_request_statuses_attributes,
    :wiki_permissions, :default_merge_request_status_id, :owner_id)

  serialize :features, Array

  def self.human_name
    I18n.t("activerecord.models.project")
  end

  def self.per_page
    20
  end

  def self.top_tags(limit = 10)
    tag_counts(:limit => limit, :order => "count desc")
  end

  # Returns the projects limited by +limit+ who has the most activity within
  # the +cutoff+ period
  def self.most_active_recently(limit = 10, number_of_days = 3)
    active(number_of_days).limit(limit)
  end

  def self.active(number_of_days = 30)
    select("distinct projects.*, count(events.id) as event_count").
      where("events.created_at > ?", number_of_days.days.ago).
      joins(:events).
      group("projects.id")
  end

  scope :order_by_title, order("title")
  scope :order_by_activity, order("events.id desc")

  def self.active_count
    active.count.count
  end

  def recently_updated_group_repository_clones(limit = 5)
    self.repositories.by_groups.order("last_pushed_at desc").limit(limit)
  end

  def recently_updated_user_repository_clones(limit = 5)
    self.repositories.by_users.order("last_pushed_at desc").limit(limit)
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

  def members
    repositories.mainlines.map(&:committerships).flat_map(&:committers).uniq
  end

  def owned_by_group?
    ["Group","LdapGroup"].include?(owner_type)
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

  # TODO: move this to the view presentation layer
  def stripped_description
    description.gsub(/<\/?[^>]*>/, "") if description.present?
  end

  def descriptions_first_paragraph
    description[/^([^\n]+)/, 1]
  end

  def to_xml(opts = {}, mainlines = [], clones = [])
    info = Proc.new { |options|
      builder = options[:builder]
      builder.owner(owner.to_param, :kind => (owned_by_group? ? "Team" : "User"))

      builder.repositories(:type => "array") do |repos|
        builder.mainlines :type => "array" do
          mainlines.each { |repo|
            builder.repository do
              builder.id repo.id
              builder.name repo.name
              builder.owner repo.owner.to_param, :kind => (repo.owned_by_group? ? "Team" : "User")
              builder.clone_url repo.clone_url
            end
          }
        end
        builder.clones :type => "array" do
          clones.each { |repo|
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
    event = events.create({
        :action => action_id,
        :target => target,
        :user => user,
        :body => body,
        :data => data,
        :created_at => date
      })
  end

  def new_event_required?(action_id, target, user, data)
    events_count = events.where("action = :action_id AND target_id = :target_id AND target_type = :target_type AND user_id = :user_id and data = :data AND created_at > :date_threshold",
                                {
                                  :action_id => action_id,
                                  :target_id => target.id,
                                  :target_type => target.class.name,
                                  :user_id => user.id,
                                  :data => data,
                                  :date_threshold => 1.hour.ago
                                }).count
    return events_count < 1
  end

  # TODO: Add tests
  def oauth_consumer
    @oauth_consumer ||= OAuth::Consumer.new(oauth_signoff_key, oauth_signoff_secret, oauth_consumer_options)
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

  def search_repositories(term)
    Repository.title_search(term, "project_id", id)
  end

  def wiki_permissions
    wiki_repository.wiki_permissions
  end

  def wiki_permissions=(perms)
    wiki_repository.wiki_permissions = perms
  end

  # Returns a String representation of the merge request states
  def merge_request_states
    (has_custom_merge_request_states? ?
     merge_request_custom_states :
     merge_request_default_states).join("\n")
  end

  def merge_request_states=(s)
    self.merge_request_custom_states = s.split("\n").collect(&:strip)
  end

  def merge_request_fixed_states
    ["Merged", "Rejected"]
  end

  def merge_request_default_states
    ["Open", "Closed", "Verifying"]
  end

  def has_custom_merge_request_states?
    !merge_request_custom_states.blank?
  end

  def default_merge_request_status_id
    if status = merge_request_statuses.default
      status.id
    end
  end

  def default_merge_request_status_id=(status_id)
    merge_request_statuses.each do |status|
      if status.id == status_id.to_i
        status.update_attribute(:default, true)
      else
        status.update_attribute(:default, false)
      end
    end
  end

  def suspended?
    !suspended_at.nil?
  end

  def suspend!
    self.suspended_at = Time.now
  end

  def slug=(slug)
    self[:slug] = (slug || "").downcase
  end

  def uniq?
    project = Project.where("lower(slug) = ?", slug).first
    project.nil? || project == self
  end

  def merge_requests
    MergeRequest.where("project_id = ?", id).joins(:target_repository)
  end

  def self.reserved_slugs
    @reserved_slugs ||= []
  end

  def self.reserve_slugs(slugs)
    @reserved_slugs ||= []
    @reserved_slugs.concat(slugs)
  end

  def self.private_on_create?(params = {})
    return false if !Gitorious.private_repositories?
    params[:private] || Gitorious.repositories_default_private?
  end
end
