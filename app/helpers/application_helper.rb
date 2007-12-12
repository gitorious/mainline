# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  
  def default_css_tag_sizes
    %w(tag_size_1 tag_size_2 tag_size_3 tag_size_4)
  end
  
  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), { :action => :category, :id => tag.name })
    end.to_sentence
  end
end
