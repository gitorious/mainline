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
  
  HIGHLIGHTER_TO_EXT = {
    "list"  => /\.(lisp|cl|l|mud|el)$/,
    "hs"    => /\.hs$/,
    "css"   => /\.css$/,
    "lua"   => /\.lua$/,
    "ml"    => /\.(ml|mli)$/,
    "proto" => /\.proto$/,
    "sql"   => /\.(sql|ddl|dml)$/,
    "vb"    => /\.vb$/,
    "wiki"  => /\.(mediawiki|wikipedia|wiki)$/,
  }
  
  def language_of_file(filename)
    HIGHLIGHTER_TO_EXT.find{|lang, matcher| filename =~ matcher }
  end
  
  def render_highlighted(text, filename, code_theme_class = nil)
    out = []
    out << %Q{<table id="codeblob" class="highlighted">}
    text.to_s.split("\n").each_with_index do |line, count|
      lineno = count + 1
      out << %Q{<tr id="line#{lineno}">}
      out << %Q{<td class="line-numbers"><a href="#line#{lineno}" name="line#{lineno}">#{lineno}</a></td>} 
      code_classes = "code"
      code_classes << " #{code_theme_class}" if code_theme_class
      ext = File.extname(filename).sub(/^\./, '')
      out << %Q{<td class="#{code_classes}"><pre class="prettyprint lang-#{ext}">#{h(line)}</pre></td>}
      out << "</tr>"
    end
    out << "</table>"
    out.join("\n")
  end
  
  def too_big_to_render?(size)
    size > 350.kilobytes
  end
end
