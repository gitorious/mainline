atom_feed do |feed|
  feed.title("Gitorious: #{@user.login}'s activity")
  feed.updated((@events.blank? ? Time.now : @events.first.created_at))

  @events.each do |event|
    action, body, category = action_and_body_for_event(event)
    item_url = "http://#{GitoriousConfig['gitorious_host']}" + user_path(@user)
    feed.entry(event, :url => item_url) do |entry|
      entry.title("#{h(event.user.login)} #{strip_tags(action)}")
      entry.content(<<-EOS, :type => 'html')
<p>#{link_to event.user.login, user_path(event.user)} #{action}</p>
<p>#{body}<p>
EOS
      entry.author do |author|
        author.name(event.user.login)
      end
    end
  end
end