# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

class Event < ActiveRecord::Base
  extend IndexHint

  MAX_COMMIT_EVENTS = 25

  belongs_to :user
  belongs_to :project
  belongs_to :target, :polymorphic => true
  has_many :events, :as => :target do
    def commits
      where(:action => Action::COMMIT).limit(Event::MAX_COMMIT_EVENTS + 1)
    end
  end
  has_many :feed_items, :dependent => :destroy

  after_create :create_feed_items
  after_create :notify_subscribers

  validates_presence_of :user_id, :unless => :user_email_set?

  scope :top, {
    :conditions => ["target_type != ?", Event.name],
    :order => "created_at desc",
    :include => [:user, :project]
  }
  scope :excluding_commits, {:conditions => ["action != ?", Action::COMMIT]}

  def self.latest(count)
    latest_event_ids = Event.find_by_sql(
                                         ["select id,action,created_at from events " +
                                          "#{use_index('index_events_on_created_at')} where (action != ?) " +
                                          "order by created_at desc limit ?", Action::COMMIT, count
                                         ]).map(&:id)
    Event.where(:id => latest_event_ids).
      order("created_at desc").
      includes(:user, :project, :events)
  end

  def self.latest_in_projects(count, project_ids)
    return [] if project_ids.blank?
    where("events.action != ? and events.project_id in (?)",
          Action::COMMIT,
          project_ids).
      from("#{quoted_table_name} #{use_index('index_events_on_created_at')}").
      order("events.created_at desc").
      includes(:user, :project, :events).
      limit(count)
  end

  def action_name
    Action.name(action)
  end

  def build_commit(options={})
    e = self.class.new(options.merge({
                                       :action => Action::COMMIT,
                                       :project_id => project_id
                                     }))
    e.target = self
    return e
  end

  def has_commits?
    return false if self.action != Action::PUSH
    !events.blank? && !events.commits.blank?
  end

  def single_commit?
    return false unless has_commits?
    return events.size == 1
  end

  def commit_event?
    action == Action::COMMIT
  end

  def kind
    "commit"
  end

  def email=(an_email)
    if u = User.find_by_email_with_aliases(an_email)
      self.user = u
    else
      self.user_email = an_email
    end
  end

  def git_actor
    @git_actor ||= find_git_actor
  end

  # Initialize a Grit::Actor object: If only the email is provided, we
  # will give back anything before '@' as name and email as email. If
  # both name and email is provided, we will give an Actor with both.
  # If a User object, an Actor with name and email
  def find_git_actor
    if user
      Grit::Actor.new(user.fullname, user.email)
    else
      a = Grit::Actor.from_string(user_email)
      if a.email.blank?
        return Grit::Actor.new(a.name.to_s.split("@").first, a.name)
      else
        return a
      end
    end
  end

  def email
    git_actor.email
  end

  def actor_display
    git_actor.name
  end

  def notifications_disabled?
    commit_event?
  end

  def notify_subscribers
    EmailEventSubscribers.call(self)
  end

  def self.events_for_archive_in_batches(created_before)
    find_in_batches(:conditions => ["created_at < ? AND target_type != ?", created_before, Event.name]) do |batch|
      yield batch if block_given?
      logger.info("Event archiving: archived one batch of events")
    end
  end

  def self.archive_events_older_than(created_before)
    events_for_archive_in_batches(created_before) do |batch|
      Event.transaction do
        batch.each do |event|
          event.create_archived_event
          event.destroy
        end
      end
    end
  end

  def create_archived_event
    result = ArchivedEvent.new
    result.attributes = attributes
    result.save
    events.each do |event|
      commit = ArchivedEvent.new
      commit.attributes = event.attributes
      commit.target_id = result.to_param
      commit.save
      event.destroy
    end
    result
  end

  def diff_body(start_sha, end_sha)
    target.git.git.show({}, [start_sha, end_sha].join(".."))
  end

  protected
  def user_email_set?
    !user_email.blank?
  end

  def create_feed_items
    return if self.action == Action::COMMIT
    FeedItem.bulk_create_from_watcher_list_and_event!(watcher_ids, self)
  end

  # Get a list of user ids who are watching the project and target of
  # this event, excluding the event creator (since he's probably not
  # interested in his own doings).
  def watcher_ids
    # Find all the watchers of the project
    watcher_ids = self.project.watchers.select("users.id").map(&:id)
    # Find anyone who's just watching the target, if it's watchable
    if self.target.respond_to?(:watchers)
      watcher_ids += self.target.watchers.select("users.id").map(&:id)
    end
    watcher_ids.uniq.select{|an_id| an_id != self.user_id }
  end
end
