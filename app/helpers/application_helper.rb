# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  include JavaScriptMacrosHelper
  
  def default_css_tag_sizes
    %w(tag_size_1 tag_size_2 tag_size_3 tag_size_4)
  end
  
  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), { :action => :category, :id => tag.name })
    end.to_sentence
  end
  
  def render_build_notice_for?(object)
    object.respond_to?(:ready?) && !object.ready?
  end
  
  # TODO: refactor into a block that "disables" everything within it until ready
  def render_build_notice_for(object)
    return unless render_build_notice_for?(object)
    out =  %Q{<div class="being_constructed">}
    out << %Q{  <p>The #{object.class.name.humanize.downcase} is being created,<br />}
    out << %Q{  it will be ready pretty soon&hellip;</p>}
    out << %Q{</div>}
    out
  end
end
