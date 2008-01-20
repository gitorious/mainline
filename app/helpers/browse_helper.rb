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
  
  def render_inline_diff(udiff, src_sha, dst_sha)
    callback = Gitorious::Diff::InlineTableCallback.new
    out = %Q{<table class="codediff inline">\n}
    out << "<thead>\n"
    out << "<tr>"
    out << %Q{<td class="line-numbers">#{src_sha}</td>}
    out << %Q{<td class="line-numbers">#{dst_sha}</td>}
    out << "<td>&nbsp</td></tr>\n"
    out << "</thead>\n"
    out << Diff::Display::Unified::HTMLRenderer.run(udiff, callback)
    out << "</table>"
    out
  end
  
  def render_sidebyside_diff(udiff, src_sha, dst_sha)
    callback = Gitorious::Diff::SidebysideTableCallback.new
    out = %Q{<table class="codediff sidebyside">\n}
    out << %Q{<colgroup class="left"><col class="lines"/><col class="code"/></colgroup>}
    out << %Q{<colgroup class="right"><col class="lines"/><col class="code"/></colgroup>}
    out << %Q{<thead><th colspan="2">#{src_sha}</th>}
    out << %Q{<th colspan="2">#{dst_sha}</th></thead>}
    out << Diff::Display::Unified::HTMLRenderer.run(udiff, callback)
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
  
  def with_line_numbers(&block)
    out = []
    #yield.split("\n").each_with_index{ |s,i| out << "#{i+1}: #{s}" }
    out << %Q{<table id="codeblob">}
    yield.to_s.split("\n").each_with_index do |line, count|
      lineno = count + 1
      out << %Q{<tr id="line#{lineno}">}
      out << %Q{<td class="line-numbers"><a href="#line#{lineno}" name="line#{lineno}">#{lineno}</a></td>} 
      out << %Q{<td class="code">#{line}</td>}
      out << "</tr>"
    end
    out << "</table>"
    out.join("\n")
    
  end
  
end
