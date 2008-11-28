#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

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
    begin
      highlighted = Uv.parse(text, "xhtml", syntax_name, false, theme)
    rescue => e
      if e.to_s =~ /Oniguruma Error/
        highlighted = text
      else
        raise e
      end
    end
    line_numbers_for(highlighted, theme)
  end
  
  def too_big_to_render?(size)
    size > 150.kilobytes
  end
end
