atom_feed do |feed|
  feed.title("Gitorious: projects")
  feed.updated((@projects.blank? ? Time.now : @projects.first.created_at))

  @projects.each do |project|
    item_url = "http://GitoriousConfig['gitorious_host']" + project_path(project)
    feed.entry(project, :url => item_url) do |entry|
      entry.title(project.title)
      entry.content(project.description)
      entry.author do |author|
        author.name(project.user.login)
      end
    end
  end
end