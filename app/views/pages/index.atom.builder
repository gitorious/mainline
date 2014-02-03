# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious
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

namespaced_atom_feed do |feed|
  feed.title("#{h(owner.title)} Wiki changes")
  feed.updated((commits.blank? ? nil : commits.first.committed_date))

  commits.each do |commit|
    diffs = commit.diffs
    next if diffs.blank?

    # TODO: we only find the first page changed for now:
    first_page = diffs.first.a_path.split(".").first
    item_url = page_history_url(owner, first_page, :html) rescue wiki_index_url(owner)
    feed.entry(commit, {
      :url => item_url,
      :updated => commit.committed_date.utc,
      :published => commit.committed_date.utc
    }) do |entry|
      entry.title(truncate(commit.message, :length => 100))
      entry.content(<<-EOS, :type => 'html')
<p>#{h(commit.author.name)} changed page #{h(first_page)}</p>

<pre>
#{commit.diffs.map{|d| d.diff }.join("\n")}
<pre>

EOS
      entry.author do |author|
        author.name(commit.author.name)
      end
    end
  end
end
