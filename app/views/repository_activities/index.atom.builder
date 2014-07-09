# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

namespaced_atom_feed do |feed|
  feed.title("Gitorious: #{repository.url_path} activity")
  feed.updated((events.blank? ? Time.now : events.first.created_at))

  events.map { |event| EventPresenter.build(event, self) }.each do |event|
    item_url = project_repository_commits_path(repository.project, repository, :only_path => false)
    feed.entry(event, :url => item_url) do |entry|
      entry.updated(event.created_at.iso8601)
      entry.title("#{h(event.actor_display)} #{strip_tags(event.action)}")
entry_content = <<-EOS
<p>#{event.user ? link_to(event.user.login, user_url(event.user)) : ''} #{event.action}</p>
<p>#{event.body}</p>
<p></p>
EOS
      entry.content(entry_content, :type => "html")
      entry.author do |author|
        author.name(event.actor_display)
      end
    end
  end
end
