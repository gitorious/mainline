module TreesHelper
  include RepositoriesHelper
  
  def current_path
    params[:path].dup
  end
  
  def build_tree_path(path)
    current_path << path
  end
  
  def breadcrumb_path(root_name = "root", commit_id = params[:id])
    out = %Q{<ul class="path_breadcrumbs">\n}
    visited_path = []
    out <<  %Q{  <li>/ #{link_to(root_name, tree_path(commit_id, []))}</li>\n}
    current_path.each_with_index do |path, index|
      visited_path << path
      if visited_path == current_path
        out << %Q{  <li>/ #{path}</li>\n}
      else
        out << %Q{  <li>/ #{link_to(path, tree_path(commit_id, visited_path))}</li>\n}
      end
    end
    out << "</ul>"
    out
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
  
  # FIXME: This really belongs somewhere else, but where?
  def commit_for_tree_path(repository, path)
    repository.git.log(params[:id], path, 1 => true).first
  end
end
