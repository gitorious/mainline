module BreadcrumbsHelper
  def render_breadcrumb_starting_from(root)
    result = []
    html = ''
    if current_breadcrumb = root
      until current_breadcrumb.nil?
        result << current_breadcrumb
        current_breadcrumb = current_breadcrumb.breadcrumb_parent
      end
    end
    result.reverse.each do |crumb|
      css_klass = if crumb.respond_to?(:breadcrumb_css_class)
        crumb.breadcrumb_css_class
      else
        crumb.class.to_s.demodulize.downcase
      end
      html << content_tag(:li, breadcrumb_link_to(crumb), :class => css_klass)
    end
    return html
  end
  
  def breadcrumb_link_to(an_object)
    url = case an_object
    when Repository
      project_repository_path(@project, @repository)
    when Project
      project_path(an_object)
    when Breadcrumb::Branch
      project_repository_log_path(@project, @repository, an_object.title)
    when Breadcrumb::Folder
      tree_path(params[:id], an_object.paths)
    when Breadcrumb::Blob
      blob_path(params[:id], an_object.path)
    when Breadcrumb::Commit
      commit_path(an_object.sha)
    else
      "/"
    end
    link_to(an_object.title, url)
  end
end