module PagesHelper
  
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
  
end
