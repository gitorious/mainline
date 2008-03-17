module BlobsHelper
  include RepositoriesHelper
  include TreesHelper
  
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
  
  def render_highlighted(text, filename, theme = "idle")
    syntax_name = Uv.syntax_names_for_data(filename, text).first #TODO: render a choice select box if > 1
    highlighted = Uv.parse(text, "xhtml", syntax_name, false, theme)
    line_numbers_for(highlighted, theme)
  end
  
  def too_big_to_render?(size)
    size > 150.kilobytes
  end
end
