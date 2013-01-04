# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
    "apollo"=> /\.(apollo|agc|aea)$/,
    "css"   => /\.css$/,
    "hs"    => /\.hs$/,
    "list"  => /\.(lisp|cl|l|mud|el|clj)$/,
    "lua"   => /\.lua$/,
    "ml"    => /\.(ml|mli)$/,
    "proto" => /\.proto$/,
    "scala" => /\.scala$/,
    "sql"   => /\.(sql|ddl|dml)$/,
    "vb"    => /\.vb$/,
    "vhdl"  => /\.(vhdl|vhd)$/,
    "wiki"  => /\.(mediawiki|wikipedia|wiki)$/,
    "yaml"  => /\.(yaml|yml)$/,
  }

  ASCII_MIME_TYPES_EXCEPTIONS = [ /^text/ ]

  def textual?(blob)
    !binary?(blob)
  end

  def binary?(blob)
    blob.binary?
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
    if lang_tuple = HIGHLIGHTER_TO_EXT.find{|lang, matcher| filename =~ matcher }
      return lang_tuple.first
    end
  end

  def render_highlighted(text, filename, code_theme_class = nil)
    render_highlighted_list(text.to_s.split("\n"), filename, {:code_theme_class => code_theme_class})
  end

  def render_blame(blame, filename)
    render_highlighted_list(blame.lines.map(&:line), filename, :commits => blame.lines.map(&:commit))
  end

  def render_highlighted_list(lines, filename, options={})
    out = []
    code_theme_class = options[:code_theme_class]
    commits = options[:commits]
    lang_class = "lang" + File.extname(filename).sub('.', '-')
    out << %Q{<table id="codeblob" class="highlighted #{lang_class}">}
    renderer = BlameRenderer.new(self, @project, @repository)
    lines.each_with_index do |line, count|
      lineno = count + 1
      out << %Q{<tr id="line#{lineno}">}
      out << renderer.blame_info_for_commit(commits[count]) if commits
      out << %Q{<td class="line-numbers"><a href="#line#{lineno}" name="line#{lineno}">#{lineno}</a></td>}
      code_classes = "code"
      code_classes << " #{code_theme_class}" if code_theme_class
      ext = h(File.extname(filename).sub(/^\./, ''))
      out << %Q{<td class="#{code_classes}"><pre class="prettyprint lang-#{ext}">#{h(line)}</pre></td>}
      out << "</tr>"
    end
    out << "</table>"
    out.join("\n").html_safe
  end

  def too_big_to_render?(size)
    size > 350.kilobytes
  end

  class BlameRenderer
    attr_reader :helper
    def initialize(helper, project, repository)
      @helper = helper
      @project = project
      @repository = repository
    end

    def blame_info_for_commit(commit)
      return %Q{<td class="blame_info unchanged"></td>} if commit.id == @previous_sha
      author = commit.author.name
      time = commit.committed_date.strftime("%Y-%m-%d")
      commit_link = helper.link_to("<strong>#{commit.id_abbrev}</strong> by #{author} at #{time}",
                                   helper.project_repository_commit_path(@project, @repository, commit.id),
                                   :title => commit.short_message)
      first = ' first' if not @previous_sha
      @previous_sha = commit.id
      %Q{<td class="blame_info#{first}">#{commit_link}</td>}
    end
  end
end
