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
  
  def selected_if_current_page(url_options)
    "selected" if current_page?(url_options)
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
    default = "http://#{GitoriousConfig['gitorious_host']}/images/default_face.png"
    "http://www.gravatar.com/avatar.php?default=#{default}&amp;gravatar_id=#{Digest::MD5.hexdigest(email)}#{options.map { |k,v| "&amp;#{k}=#{v}" }.join}"
  end
  
  def gravatar(email, options = {})
    size = options[:size]
    image_options = { :alt => "avatar" }
    if size
      image_options.merge!(:width => size, :height => size)
    end
    image_tag(gravatar_url_for(email, options), image_options)
  end
  
  def flashes
    flash.map { |type, content| content_tag(:div, content_tag(:p, content), :class => "flash_message #{type}")}
  end
  
  def commit_graph_tag(project, sha = "master", width = 250, height = 150)
    repo = project.mainline_repository
    git_repo = repo.git
    git = git_repo.git
    
    h = Hash.new
    dategroup = Date.new
    
    data = git.rev_list({:pretty => "format:%aD", :since => "24 weeks ago"}, sha)
    data.each_line { |line|
      if line =~ /\d\d:\d\d:\d\d/ then
        date = Date.parse(line)
        
        dategroup = Date.new(date.year, date.month, 1)
        if h[dategroup]
          h[dategroup] += 1
        else
          h[dategroup] = 1
        end
      end
    }
    
    commits = []
    labels = []
    h.sort.each { |entry|
      date = entry.first
      value = entry.last
      
      labels << date.strftime("%m/%y")
      commits << value
    }
    
    Gchart.line(:data => commits, :labels => labels, :width => width, :height => height, :bg => "efefef", :format => "img_tag")
  end
  
  def commit_graph_by_author_tag(project, sha = "master", width = 400, height = 200)
    repo = project.mainline_repository
    git_repo = repo.git
    git = git_repo.git
    
    h = Hash.new
    
    data = git.rev_list({:pretty => "format:name:%cn", :since => "1 years ago" }, sha)
    data.each_line { |line|
      if line =~ /^name:(.*)$/ then
        author = $1
        
        if h[author]
          h[author] += 1
        else
          h[author] = 1
        end
      end
    }
    
    sorted = h.sort_by { |author, commits|
      commits
    }
    
    labels = []
    data = []
    
    max = 5
    others = []
    top = sorted
    
    
    if sorted.size > max
      top = sorted[sorted.size-max, sorted.size]
      others = sorted[0, sorted.size-max]
    end
    
    top.each { |entry|
      author = entry.first
      v = entry.last
      
      data << v
      labels << author
    }
    
    unless others.empty?
      others_v = others.inject { |v, acum| [v.last + acum.last] }
      labels << "others"
      data << others_v.last
    end
    
    Gchart.pie(:data => data, :labels => labels, :width => width, :height => height, :bg => "efefef", :format => "img_tag" )
  end
end
