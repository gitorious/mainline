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

atom_feed do |feed|
  feed.title("Gitorious: #{@repository.url_path} merge requests")
  feed.updated((@open_merge_requests.blank? ? Time.now : @open_merge_requests.first.created_at))

  @open_merge_requests.each do |mr|
    item_url = url_for(:overwrite_params => {
        :action => "show",
        :id => mr.to_param,
        :format => nil
      }, :only_path => false)
    feed.entry(mr, :url => item_url) do |entry|
      entry.title("##{h(mr.id)}: " + h(mr.summary))
      entry.content((<<-EOS), :type => "html")
<strong>#{h(mr.summary)}</strong><br /><br />
#{h(mr.proposal)}
<hr />
Status: #{h(mr.status_tag.to_s)}
EOS
      entry.author do |author|
        author.name(mr.user.login)
      end
    end
  end
end
