# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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
  
  ASCII_MIME_TYPES_EXCEPTIONS = [ /^text/ ]
  
  def textual?(blob)
    types = MIME::Types.type_for(blob.name)
    if types.first && types.first.ascii?
      return true
    end
    if ASCII_MIME_TYPES_EXCEPTIONS.find{|r| r =~ blob.mime_type }
      return true
    end
    false
  end
  
  def image?(blob)
    blob.mime_type =~ /^image/
  end
  
  def highlightable?(blob)
    if File.extname(blob.name) == ""
      return false
    end
    if %w[.txt .textile .md .rdoc .markdown].include?(File.extname(blob.name))
      return false
    end
    true
  end
  
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
