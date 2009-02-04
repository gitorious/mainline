class GitoriousFormBuilder < ActionView::Helpers::FormBuilder
  
  # Creates a set of radio buttons for the current_user and a select tag
  # for any groups he's a member of
  def current_user_or_group(field, label_title, hint = nil, options = {})
    result = [label(field, label_title), "<br />"]
    result << "Me: " + radio_button("#{field}_type", "User")
    result << "Group: " + radio_button("#{field}_type", "Group")
    result << select("#{field}_id", @template.current_user.groups.map{|g| [g.name, g.id] }, 
                      {}, :id => "#{object_name}_#{field}_id_group_select")
    if options[:hint]
      result << content_tag(:p, options[:hint], :class => "hint")
    end
    result
  end
end