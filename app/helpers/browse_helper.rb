module BrowseHelper
  
  def browse_path
    project_repository_browse_path(@project, @repository)
  end
  
  def tree_path(sha1=nil)
    project_repository_tree_path(@project, @repository, sha1)    
  end
  
  def commit_path(sha1)
    project_repository_commit_path(@project, @repository, sha1)    
  end
  
  def blob_path(sha1, filename)
    project_repository_blob_path(@project, @repository, sha1, filename)    
  end
  
  def raw_blob_path(sha1, filename)
    project_repository_raw_blob_path(@project, @repository, sha1, filename)    
  end
  
  def diff_path(sha1, other_sha1)
    project_repository_diff_path(@project, @repository, sha1, other_sha1)    
  end
    
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
    out << Diff::Display::Unified::Renderer.run(udiff, callback)
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
    out << Diff::Display::Unified::Renderer.run(udiff, callback)
    out << "</table>"
    out
  end
  
  def render_diffmode_selector
    out = %Q{<ul class="diffmode_selector">}
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
  
end
