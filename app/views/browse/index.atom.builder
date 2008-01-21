atom_feed do |feed|
  feed.title("Gitorious: #{@project.title} - #{@repository.name}")
  feed.updated((@commits.blank? ? nil : @commits.first.date))

  @commits.each do |commit|
    item_url = "http://gitorious.org" +  project_repository_commit_path(@project, @repository, commit.sha)
    feed.entry(commit.sha, {
      :url => item_url, 
      :updated => commit.date, 
      :published => commit.date,
      :id => "#{@repository.name}:#{commit.sha}"
    }) do |entry|
      entry.title(truncate(commit.message, 75))
      entry.content(<<-EOS, :type => 'html')
<h1>In #{@repository.gitdir}</h1>
<pre>
Date:   #{commit.date.strftime("%Y-%m-%d %H:%M")}
Author: #{commit.author.name} (#{commit.author.email})
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