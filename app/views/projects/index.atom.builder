atom_feed do |feed|
  feed.title("Gitorious: projects")
  feed.updated((@projects.first.created_at))

  @projects.each do |project|
    item_url = "http://gitorious.org" + project_path(project)
    feed.entry(project, :url => item_url) do |entry|
      entry.title(project.title)
      entry.content(project.description)
      entry.author do |author|
        author.name("Gitorious")
      end
    end
  end
end