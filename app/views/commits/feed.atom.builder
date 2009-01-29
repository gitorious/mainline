#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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
  feed.title("Gitorious: #{@project.title} - #{@repository.name}")
  feed.updated((@commits.blank? ? nil : @commits.first.committed_date))
	
  @commits.each do |commit|
    item_url = "http://#{GitoriousConfig['gitorious_host']}" +  project_repository_commit_path(@project, @repository, commit.id)
    #stats.files.each do |filename, adds, deletes, total|
		commit_stat_data = commit.stats.files.map do |file, insertions, deletions, total| 
			[insertions.to_s.ljust(8, " "), deletions.to_s.ljust(8, " "), file].join
		end
    feed.entry(commit, {
      :url => item_url, 
      :updated => commit.committed_date, 
      :published => commit.committed_date
    }) do |entry|
      entry.title(truncate(commit.message, :length => 75))
      entry.content(<<-EOS, :type => 'html')
<h1>In #{@repository.gitdir} #{params[:id]}</h1>
<pre>
#{word_wrap commit.message}


Date:   #{commit.committed_date.strftime("%Y-%m-%d %H:%M")}
Author: #{commit.author.name}
Committer: #{commit.committer.name}

#{commit.stats.total} lines changed in #{commit.stats.files.length} files:
------------------------------------------------------------------------------
adds   dels     file
------------------------------------------------------------------------------
#{commit_stat_data.join("\n")}
<pre>
EOS
      entry.author do |author|
        author.name(commit.author.name)
      end
    end
  end
end