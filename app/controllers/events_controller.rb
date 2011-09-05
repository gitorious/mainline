# encoding: utf-8
#--
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class EventsController < ApplicationController
  def index
    @events = paginate(page_free_redirect_options) do
      Event.paginate(:all, :order => "events.created_at desc",
                     :page => params[:page], :include => [:user])
    end

    return if @events.count == 0 && params.key?(:page)
    @atom_auto_discovery_url = events_path(:format => :atom)

    respond_to do |if_format_is|
      if_format_is.html {}
      if_format_is.atom {}
    end
  end

  def commits
    @event = Event.find(params[:id])
    @repository = @event.target
    @project = @repository.project
    if @event.action == Action::PUSH
      render_old_style_push
    else
      render_new_style_push
    end
  end

  # TODO: Remove when old push events are removed
  def render_old_style_push
    @commit_count = @event.events.count
    @branch_name = @event.data
    if stale?(:etag => @event, :last_modified => @event.created_at)
      @commits = @event.events.commits
      respond_to do |wants|
        wants.js
      end
      expires_in 30.minutes
    end
  end

  def render_new_style_push
    event_data = PushEventLogger.parse_event_data(@event.data)
    @branch_name = event_data[:branch]
    @commit_count = event_data[:commit_count].to_i
    first_sha = event_data[:start_sha]
    last_sha = event_data[:end_sha]
    if stale?(:etag => @event, :last_modified => @event.created_at)
      @commits = Gitorious::Commit.load_commits_between(@event.target.git, first_sha, last_sha, @event.id)[0,Event::MAX_COMMIT_EVENTS + 1]
      respond_to do |wants|
        wants.js
      end
      expires_in 30.minutes
    end
  end
end
