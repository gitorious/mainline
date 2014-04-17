# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2008, 2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
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
  feed.title("Gitorious: #{repository.name} comments")
  feed.updated((comments.blank? ? Time.now : comments.first.created_at))

  comments.each do |comment|
    item_url = Gitorious.url(project_repository_path(project, repository))
    feed.entry(comment, :url => item_url) do |entry|
      entry.title("#{comment.user.login}: #{truncate(comment.body, :length => 30)}")
      entry.content(comment.body)
      entry.author do |author|
        author.name(comment.user.login)
      end
    end
  end
end
