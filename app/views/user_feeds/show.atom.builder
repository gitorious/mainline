# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
  feed.title("Gitorious: #{user.login}'s activity")
  feed.updated((events.blank? ? Time.now : events.first.created_at))

  events.map { |event| EventPresenter.build(event, self) }.each do |event|
    user_title = !event.user.nil? ? event.user.login : mangled_mail(event.user_email)

    feed.entry(event, :url => Gitorious.url(user_path(user))) do |entry|
      entry.updated(event.created_at.iso8601)
      entry.title("#{h(user_title)} #{strip_tags(event.action)}")
      content =
        if event.user.nil?
          ""
        else
          "<p>#{link_to event.user.login, user_url(event.user)} #{event.action}</p>"
        end

      entry.content(<<-EOS, :type => 'html')
#{content}
<p>#{event.body}<p>
EOS
      entry.author do |author|
        author.name(user_title)
      end
    end
  end
end
