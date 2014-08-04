# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
  feed.title("Gitorious: #{h(@repository.gitdir)}:#{@ref}")
  feed.updated((@commits.blank? ? nil : @commits.first.committed_date))

  @commits.each do |commit|
    item_url = Gitorious.url(project_repository_commit_path(@project, @repository, commit.id))
    feed.entry(commit, {
      :url => item_url,
      :updated => commit.committed_date.utc,
      :published => commit.committed_date.utc
    }) do |entry|
      entry.title(truncate(commit.message, :length => 100))
      entry.content(<<-EOS, :type => 'html')
<h2>In #{@repository.gitdir}:#{h(@ref)}</h2>

<ul>
  <li><strong>Commit:</strong> #{link_to(commit.id, item_url)}</li>
  <li><strong>Date:</strong> #{commit.committed_date.utc.strftime("%Y-%m-%d %H:%M")}</li>
  <li><strong>Author:</strong> #{commit.author.name}</li>
  <li><strong>Committer:</strong> #{commit.committer.name}</li>
</ul>

<pre>
#{h word_wrap(commit.message)}
</pre>

EOS
      entry.author do |author|
        author.name(commit.author.name)
      end
    end
  end
end
