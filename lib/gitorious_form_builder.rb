class GitoriousFormBuilder < ActionView::Helpers::FormBuilder
  
  # Creates a set of radio buttons for the current_user and a select tag
  # for any groups he's a member of
  def current_user_or_group(field, label_title, hint = nil, options = {})
    result = [label(field, label_title), ""]
    result << "<div>"
    result << "Me: " + radio_button("#{field}_type", "User", {:checked => true})
    result << select_group_membership(field)
    if options[:hint]
      result << content_tag(:p, options[:hint], :class => "hint")
    end
    result << "</div>"
    result.join("\n")
  end
  
  private

  def select_group_membership(field)
    admin_groups = @template.current_user.groups.select {|g| g.admin? @template.current_user }
    result = ""
    unless admin_groups.empty?
      result << "Group: " + radio_button("#{field}_type", "Group")
      result << select("#{field}_id", admin_groups.map{|g| [g.name, g.id] }, 
                        {}, :id => "#{object_name}_#{field}_id_group_select")
    end
    result    
  end
end
