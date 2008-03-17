atom_feed do |feed|
  feed.title("Gitorious: #{@project.title} - #{@repository.name}")
  feed.updated((@commits.blank? ? nil : @commits.first.committed_date))

  @commits.each do |commit|
    item_url = "http://GitoriousConfig['gitorious_host']" +  project_repository_commit_path(@project, @repository, commit.id)
    feed.entry(commit.id, {
      :url => item_url, 
      :updated => commit.committed_date, 
      :published => commit.committed_date,
      :id => "#{@repository.name}:#{commit.id}"
    }) do |entry|
      entry.title(truncate(commit.message, 75))
      entry.content(<<-EOS, :type => 'html')
<h1>In #{@repository.gitdir}</h1>
<pre>
Date:   #{commit.committed_date.strftime("%Y-%m-%d %H:%M")}
Committer: #{commit.committer.name} (#{commit.committer.email})
Message:
#{commit.message}
<pre>
EOS
      entry.author do |author|
        author.name(commit.author.name)
      end
    end
  end
end