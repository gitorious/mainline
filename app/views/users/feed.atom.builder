# encoding: utf-8
#--
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

atom_feed do |feed|
  feed.title("Gitorious: #{@user.login}'s activity")
  feed.updated((@events.blank? ? Time.now : @events.first.created_at))

  @events.each do |event|
    user_title = !event.user.nil? ? event.user.login : mangled_mail(event.user_email)
    action, body, category = action_and_body_for_event(event)
    item_url = "#{GitoriousConfig['scheme']}://#{GitoriousConfig['gitorious_host']}" + user_path(@user)
    feed.entry(event, :url => item_url) do |entry|
      entry.title("#{h(user_title)} #{strip_tags(action)}")
      content = event.user.nil? ? "" : "<p>#{link_to event.user.login, user_path(event.user)} #{action}</p>"
      entry.content(<<-EOS, :type => 'html')
#{content}
<p>#{body}<p>
EOS
      entry.author do |author|
        author.name(user_title)
      end
    end
  end
end
