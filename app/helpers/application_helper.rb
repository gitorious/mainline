# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  
  def default_css_tag_sizes
    %w(tag_size_1 tag_size_2 tag_size_3 tag_size_4)
  end
  
  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), search_path(:q => "category:#{h(tag.name)}"))
    end.to_sentence
  end
  
  def build_notice_for(object)
    out =  %Q{<div class="being_constructed">}
    out << %Q{  <p>This #{object.class.name.humanize.downcase} is being created,<br />}
    out << %Q{  it will be ready pretty soon&hellip;</p>}
    out << %Q{</div>}
    out
  end
  
  def render_if_ready(object, &blk)
    if object.respond_to?(:ready?) && object.ready?
      yield
    else
      concat(build_notice_for(object), blk.binding)
    end
  end  
  
  def selected_if_current_page(url_options, slack = false)
    if slack
      if controller.request.request_uri.index(CGI.escapeHTML(url_for(url_options))) == 0
        "selected"
      end
    else
      "selected" if current_page?(url_options)
    end
  end
  
  def link_to_with_selected(name, options = {}, html_options = nil)
    html_options = current_page?(options) ? {:class => "selected"} : nil
    link_to(name, options = {}, html_options)
  end
  
  def syntax_themes_css
    out = []
    if @load_syntax_themes
      # %w[ active4d all_hallows_eve amy blackboard brilliance_black brilliance_dull 
      #     cobalt dawn eiffel espresso_libre idle iplastic lazy mac_classic 
      #     magicwb_amiga pastels_on_dark slush_poppies spacecadet sunburst 
      #     twilight zenburnesque 
      # ].each do |syntax|
      #   out << stylesheet_link_tag("syntax_themes/#{syntax}")
      # end
      return stylesheet_link_tag("syntax_themes/idle")
    end
    out.join("\n")
  end
  
  def base_url(full_url)
    URI.parse(full_url).host
  end
  
  def gravatar_url_for(email, options = {})
    "http://www.gravatar.com/avatar.php?gravatar_id=" << 
    Digest::MD5.hexdigest(email) << 
    options.map { |k,v| "&amp;#{k}=#{v}" }.join
  end
  
  def gravatar(email, options = {})
    size = options[:size]
    image_options = { :alt => "avatar" }
    if size
      image_options.merge!(:width => size, :height => size)
    end
    image_tag(gravatar_url_for(email, options), image_options)
  end
  
  def gravatar_frame(email, options = {})
    extra_css_class = options[:style] ? " gravatar_#{options[:style]}" : ""
    %{<div class="gravatar#{extra_css_class}">#{gravatar(email, options)}</div>}
  end
  
  def flashes
    flash.map { |type, content| content_tag(:div, content_tag(:p, content), :class => "flash_message #{type}")}
  end
  
  def commit_graph_tag(repository, sha = "master", width = 650, height = 110)
    labels, commits = repository.commit_graph_data(sha)
    return if commits.blank?
    
    label_names = []
    labels.each_with_index do |week, index|
      if (index % 5) == 0
        label_names << "Week #{week}"
      end
    end
    label_names << "Week #{labels.last}"
    
    # "<pre>#{labels.inspect}\n#{commits.inspect}</pre>" + 
    Gchart.line({
      :title => "Commits by week (24 week period)",
      :data => [0] + commits, 
      :width => width, 
      :height => height, 
      :format => "img_tag", 
      :axis_with_labels => ["y", "x"], 
      :axis_labels => ["|#{commits.max}", label_names.join("|")],
      :bar_colors => "9cce2e",
      :custom => "chm=B,E4E9D4,0,0,0",
      :max_value => "auto"
    })
  end
  
  def commit_graph_by_author_tag(repos, sha = "master", width = 350, height = 150)    
    labels, data = repos.commit_graph_data_by_author
    
    Gchart.pie({
      :title => "Commits by author",
      :data => data, 
      :labels => labels, 
      :width => width, 
      :height => height, 
      :bar_colors => "9cce2e",
      :format => "img_tag" 
    })
  end
end
