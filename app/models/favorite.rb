# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class Favorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :watchable, :polymorphic => true
  before_destroy :destroy_event

  validates_presence_of :user_id, :watchable_id, :watchable_type
  validates_uniqueness_of :user_id, :scope => [:watchable_id, :watchable_type]

  def event_exists?
    !Event.count(:conditions => event_options).zero?
  end

  def event_options
    {:action => Action::ADD_FAVORITE, :data => watchable.id,
      :body => watchable.class.name, :project_id => project.id,
      :target_type => "User", :target_id => user.id}
  end

  def project
    case watchable
    when MergeRequest
      watchable.target_repository.project
    when Repository
      watchable.project
    when Project
      watchable
    end
  end

  def event_should_be_created?
    !event_exists?
  end

  def create_event
    user.events.create(event_options) if event_should_be_created?
  end

  def destroy_event
    if event = Event.find(:first, :conditions => event_options)
      event.destroy
    end
  end

  def notify_about_event(an_event)
    notification_content = EventRendering::Text.render(an_event)
    Mailer.deliver_favorite_notification(self.user, notification_content)
  end
end
