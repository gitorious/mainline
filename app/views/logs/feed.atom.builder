atom_feed do |feed|
  feed.title("Gitorious: #{@project.title} - #{@repository.name}")
  feed.updated((@commits.blank? ? nil : @commits.first.committed_date))
	
  @commits.each do |commit|
    item_url = "http://#{GitoriousConfig['gitorious_host']}" +  project_repository_commit_path(@project, @repository, commit.id)
		commit_stat_data = commit.stats.files.map do |file, stats| 
			[stats[:insertions].to_s.ljust(8, " "), stats[:deletions].to_s.ljust(8, " "), file].join
		end
    feed.entry(commit, {
      :url => item_url, 
      :updated => commit.committed_date, 
      :published => commit.committed_date
    }) do |entry|
      entry.title(truncate(commit.message, 75))
      entry.content(<<-EOS, :type => 'html')
<h1>In #{@repository.gitdir}</h1>
<pre>
#{@repository.name}:#{params[:id]} in #{@project.title}

Date:   #{commit.committed_date.strftime("%Y-%m-%d %H:%M")}
Author: #{commit.author.name}
Committer: #{commit.committer.name}


#{commit.message}


#{commit.stats.total[:lines]} lines changed in #{commit.stats.total[:files]} files:
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