# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 David Aguilar <davvid@gmail.com>
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
require "gitorious/messaging"

class RepositoryBuilder
  include Gitorious::Messaging::Publisher
  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  def build
    initialize_owner_committership
    initialize_owner_membership
    initialize_owner_favorite
    create_events
    post_repo_creation_message
  end

  def initialize_owner_committership
    repository.committerships.create_for_owner!(repository.owner)
  end

  def initialize_owner_membership
    parent = repository.parent
    return if parent.nil? || parent.public?
    repository.make_private
    parent.content_memberships.each { |m| repository.add_member(m.member) }
  end

  def initialize_owner_favorite
    return if repository.internal?
    repository.watched_by!(repository.user)
  end

  # TODO: Move to event builder or project?
  def create_events
    return if !repository.project_repo?
    #(action_id, target, user, data = nil, body = nil, date = Time.now.utc)
    repository.project.create_event(Action::ADD_PROJECT_REPOSITORY,
                                    repository,
                                    repository.user,
                                    nil,
                                    nil,
                                    date = repository.created_at)
  end

  def post_repo_creation_message
    return if repository.tracking_repo?
    parent = repository.parent
    gitdir = repository.real_gitdir
    publish("/queue/GitoriousRepositoryCreation", {
      :target_class => repository.class.name,
      :target_id => repository.id,
      :command => parent ? "clone_git_repository" : "create_git_repository",
      :arguments => parent ? [gitdir, parent.real_gitdir] : [gitdir]
    })
  end
end
