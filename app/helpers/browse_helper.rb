module BrowseHelper
  
  def browse_path
    project_repository_browse_path(@project, @repository)
  end
  
  def log_path(args={})
    project_repository_log_path(@project, @repository, args)
  end
  
  def tree_path(sha1=nil, path=[])
    project_repository_tree_path(@project, @repository, sha1, path)    
  end
  
  def commit_path(sha1)
    project_repository_commit_path(@project, @repository, sha1)    
  end
  
  def blob_path(sha1, path)
    project_repository_blob_path(@project, @repository, sha1, path)    
  end
  
  def raw_blob_path(sha1, path)
    project_repository_raw_blob_path(@project, @repository, sha1, path)
  end
  
  def diff_path(sha1, other_sha1)
    project_repository_diff_path(@project, @repository, sha1, other_sha1)    
  end
  
  def current_path
    params[:path].dup
  end
  
  def build_tree_path(path)
    current_path << path
  end
  
  # def breadcrumb_path
  #   out = %Q{<ul class="path_breadcrumbs">\n}
  #   visited_path = []
  #   out <<  %Q{  <li>/ #{link_to("root", tree_path(params[:sha], []))}</li>\n}
  #   current_path.each_with_index do |path, index|
  #     visited_path << path
  #     out << %Q{  <li>/ #{link_to(path, tree_path(params[:sha], path))}</li>\n}
  #   end
  #   out << "</ul>"
  #   out
  # end
    
  def render_tag_box_if_match(sha, tags_per_sha)
    tags = tags_per_sha[sha]
    return if tags.blank?
    out = ""
    tags.each do |tagname|
      out << %Q{<span class="tag"><code>}
      out << tagname
      out << %Q{</code></span>}
    end
    out
  end  
  
  # Takes a unified diff as input and renders it as html
  def render_diff(udiff, src_sha, dst_sha, display_mode = "inline")
    return if udiff.blank?

    case display_mode
    when "sidebyside"
      render_sidebyside_diff(udiff, src_sha, dst_sha)
    else
      render_inline_diff(udiff, src_sha, dst_sha)
    end
  end
  
  #diff = Diff::Display::Unified.new(load_diff("simple"))
  #diff.render(Diff::Renderer::Base.new)
  def render_inline_diff(udiff, src_sha, dst_sha)
    differ = Diff::Display::Unified.new(udiff)
    out = %Q{<table class="codediff inline">\n}
    out << "<thead>\n"
    out << "<tr>"
    out << %Q{<td class="line-numbers">#{src_sha}</td>}
    out << %Q{<td class="line-numbers">#{dst_sha}</td>}
    out << "<td>&nbsp</td></tr>\n"
    out << "</thead>\n"
    out << differ.render(Gitorious::Diff::InlineTableCallback.new)
    out << %Q{<tr class="toggle_diff"><td colspan="3">}
    out << %Q{<small>#{link_to_function "toggle raw diff", "$('diff#{udiff.object_id}').toggle()"}</small></td></tr>}
    out << %Q{<tr class="raw_diff"><td colspan="3" style="display:none" id="diff#{udiff.object_id}">}
    out << %Q{<pre>#{h(udiff)}</pre>}
    out << "</td></tr>"
    out << "</table>"
    out
  end
  
  def render_sidebyside_diff(udiff, src_sha, dst_sha)
    differ = Diff::Display::Unified.new(udiff)
    out = %Q{<table class="codediff sidebyside">\n}
    out << %Q{<colgroup class="left"><col class="lines"/><col class="code"/></colgroup>}
    out << %Q{<colgroup class="right"><col class="lines"/><col class="code"/></colgroup>}
    out << %Q{<thead><th class="line-numbers">#{src_sha}</th><th></th>}
    out << %Q{<th class="line-numbers">#{dst_sha}</th><th></th></thead>}
    out << differ.render(Gitorious::Diff::SidebysideTableCallback.new)
    out << %Q{<tr class="toggle_diff"><td colspan="4">}
    out << %Q{<small>#{link_to_function "toggle raw diff", "$('diff#{udiff.object_id}').toggle()"}</small></td></tr>}
    out << %Q{<tr class="raw_diff"><td colspan="4" style="display:none" id="diff#{udiff.object_id}">}
    out << %Q{<pre>#{h(udiff)}</pre>}
    out << "</td></tr>"
    out << "</table>"
    out
  end
  
  def render_diffmode_selector
    out = %Q{<ul class="mode_selector">}
    out << %Q{<li class="list_header">Diff rendering mode:</li>}
    if @diffmode == "sidebyside"
      out << %Q{<li><a href="?diffmode=inline">inline</a></li>}
      out << %Q{<li class="selected">side by side</li>}
    else
      out << %Q{<li class="selected">inline</li>}
      out << %Q{<li><a href="?diffmode=sidebyside">side by side</a></li>}
    end      
    out << "</ul>"
    out
  end
  
  def line_numbers_for(data, code_theme_class = nil)
    out = []
    #yield.split("\n").each_with_index{ |s,i| out << "#{i+1}: #{s}" }
    out << %Q{<table id="codeblob" class="highlighted">}
    data.to_s.split("\n").each_with_index do |line, count|
      lineno = count + 1
      out << %Q{<tr id="line#{lineno}">}
      out << %Q{<td class="line-numbers"><a href="#line#{lineno}" name="line#{lineno}">#{lineno}</a></td>} 
      code_classes = "code"
      code_classes << " #{code_theme_class}" if code_theme_class
      out << %Q{<td class="#{code_classes}">#{line}</td>}
      out << "</tr>"
    end
    out << "</table>"
    out.join("\n")
  end
  
  def render_highlighted(text, mime_type, theme = "idle")
    syntax_name = "ruby"#syntax_name_from_mime_Type(mime_type)
    highlighted = Uv.parse(text, "xhtml", syntax_name, false, theme)
    line_numbers_for(highlighted, theme)
  end
  
  def render_diff_stats(stats)
    out = %Q{<ul class="diff_stats">\n}
    stats[:files].each_pair do |filename, stats|
      total = stats[:insertions] + stats[:deletions]
      out << %Q{<li><a href="##{h(filename)}">#{h(filename)}</a>&nbsp;#{total}&nbsp;}
      out << %Q{<small class="deletions">#{(0...stats[:deletions]).map{|i| "-" }}</small>}
      out << %Q{<small class="insertions">#{(0...stats[:insertions]).map{|i| "+" }}</small>}
      out << %Q{</li>}
    end
    out << "</ul>\n"
    out
  end
  
end
