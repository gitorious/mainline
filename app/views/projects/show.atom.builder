# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
  feed.title("Gitorious: #{project.slug} activity")
  feed.updated((events.blank? ? Time.now : events.first.created_at))

  events.map { |event| EventPresenter.build(event, self) }.each do |event|
    feed.entry(event, :url => Gitorious.url(project_path(project))) do |entry|
      entry.updated(event.created_at.iso8601)
      if event.user
        entry.title("#{h(event.user.login)} #{strip_tags(event.action)}")
        entry_content = <<-EOS
  <p>#{link_to event.user.login, user_url(event.user)} #{event.action}</p>
  <p>#{event.body}<p>
  EOS
        if event.has_commits?
          entry_content << "<ul>"
          event.events.commits.each do |commit_event|
            entry_content << %Q{<li>#{h(commit_event.git_actor.name)} }
            commit_url = project_repository_commit_url(event.target.project, event.target, commit_event.data)
            entry_content << %Q{#{link_to(h(commit_event.data[0,7]), commit_url)}}
            entry_content << %Q{: #{truncate(h(commit_event.body), :length => 75)}</li>}
          end
          entry_content << "</ul>"
        end
        entry.content(entry_content, :type => "html")
        entry.author do |author|
          author.name(event.user.login)
        end
      else
        entry.title("#{h(event.actor_display)} #{strip_tags(event.action)}")
        entry_content = <<-EOS
          <p>#{event.action}</p>
          <p>#{event.body}</p>
        EOS
        if event.has_commits?
          entry_content << "<ul>"
          event.events.commits.each do |commit_event|
            entry_content << %Q{<li>#{h(commit_event.git_actor.name)} #{h(commit_event.data[0,7])}: #{truncate(h(commit_event.event.body), :length => 75)}</li>}
          end
          entry_content << "</ul>"
        end
        entry.content(entry_content, :type => "html")
        entry.author do |author|
          author.name(event.actor_display)
        end
      end
    end
  end
end
