atom_feed do |feed|
  feed.title("Gitorious: #{@repository.name} comments")
  feed.updated((@comments.first.created_at))

  @comments.each do |comment|
    item_url = "http://gitorious.org" + project_repository_comments_path(@project,@repository)
    feed.entry(comment, :url => item_url) do |entry|
      entry.title("#{comment.user.login}: #{truncate(comment.body, 30)}")
      entry.content(comment.body)
      entry.author do |author|
        author.name(comment.user.login)
      end
    end
  end
end