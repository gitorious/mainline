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
  def render_diff(udiff, src_sha, dst_sha)
    return if udiff.blank?
    
    callback = Gitorious::Diff::InlineTableCallback.new
    
    out = %Q{<table class="codediff">\n}
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
  
end
