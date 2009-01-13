module PagesHelper
  include CommitsHelper
  
  def wikize(content)
    content = wiki_link(content)
    auto_link(textilize(sanitize(content)), :urls)
  end
  
  def wiki_link(content)
    # TODO: support nested pages
    #content.gsub(/([A-Z][a-z\/]+[A-Z][A-Za-z0-9]+)/) do |page_link|
    content.gsub(/([A-Z][a-z]+[A-Z][A-Za-z0-9]+)/) do |page_link|
      link_to(page_link, project_page_path(@project, page_link), 
                :class => "todo missing_or_existing")
    end
  end
  
  def edit_link(page)
    link_to(t("views.common.edit")+" "+t("views.pages.page"), 
          edit_project_page_path(@project, page.title))
  end
  
  def page_crumbs(page)
    return if page.title == "Home"
    crumbs = %Q{<ul class="page-crumbs">}
    crumbs << %Q{<li>#{link_to("Home", project_page_path(@project, "Home"))} &raquo;</li>}
    crumbs << %Q{<li class="current">#{page.title}</li>}
    crumbs << "</ul>"
  end
  
end
