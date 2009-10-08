# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tor.arne.vestbo@trolltech.com>
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

module CommitsHelper
  include RepositoriesHelper
  
  def format_commit_message(message)
    message.gsub(/\b[a-z0-9]{40}\b/) do |match|
      link_to(match, repo_owner_path(@repository, :project_repository_commit_path, 
                                     @project, @repository, match), :class => "sha")
    end
  end
  
  # Takes a unified diff as input and renders it as html
  def render_diff(udiff, display_mode = "inline")
    return if udiff.blank?
    
    udiff = force_utf8(udiff)
    
    if sidebyside_diff?
      render_sidebyside_diff(udiff)
    else
      render_inline_diff(udiff)
    end
  end

  def sidebyside_diff?
    @diffmode == "sidebyside"
  end

  def render_diffs(diffs)
    if sidebyside_diff?
      diffs.map do |file|
        out = %Q{<a name="#{h(force_utf8(file.a_path))}"></a>}
        out << "<h4>"
        out << link_to(h(file.a_path), file_path(@repository, file.a_path, @commit.id))
        out << "</h4>"
        out << force_utf8(render_diff(file.diff))
        out
      end.join("\n")
    else
      '<div class="clear"></div><div id="commit-diff-container">' +
        render_inline_diffs_controls("commits") +
        render_inline_diffs_with_stats(diffs, :open) + "</div>"
    end
  end

  # Supply a block that fetches an array of comments with the file path as parameter
  def render_inline_diffs_with_stats(file_diffs, state = :closed)
    file_diffs.map do |file|
      diff_renderer = Diff::Display::Unified.new(file.diff)
      out = '<div class="file-diff">'
      out << %Q{<div class="header round-top-10 #{state == :closed ? 'closed' : 'open'}">}
      out << %Q{<span class="title"><span class="icon"></span>#{h(file.a_path)}</span>}
      out << %Q{<div class="diff-stats">}
      out << render_compact_diff_stats(diff_renderer.stats)
      out << "</div></div>"
      out << %Q{<div class="diff-hunks" #{state == :closed ? 'style="display:none"' : ''}>}
      out << %Q{<div class="comment_container" style="display:none"></div>}

      if file.diff[0..256].include?("\000")
        out << "Binary files differ"
      else
        diff_options = {}
        diff_options[:comments] = if block_given?
                                    yield(file)
                end
        out << force_utf8(render_inline_diff(file.diff, diff_renderer, diff_options))
      end
      out << "</div></div>"
      out
    end.join("\n")
  end

  def render_inline_diffs_controls(cookie_prefix)
    %Q{<div class="file-diff-controls">
         <small>
           <a href="#" id="expand-all" gts:cookie-prefix="#{cookie_prefix}">expand all</a> / 
           <a href="#" id="collapse-all" gts:cookie-prefix="#{cookie_prefix}">collapse all</a>
         </small>
       </div>}
  end
  
  def render_inline_diff(udiff, differ = nil, options = {})
    differ ||= Diff::Display::Unified.new(udiff)
    out = %Q{<table class="codediff inline">\n}
    out << "<thead>\n"
    out << %Q{<tr><td class="inline_comments line-numbers">&nbsp;</td>}
    out << %Q{<td class="line-numbers"></td>}
    out << %Q{<td class="line-numbers"></td>}
    out << "<td>&nbsp</td></tr>\n"
    out << "</thead>\n"
    if comments = options[:comments]
      render_callback = Gitorious::Diff::InlineTableCallback.with_comments(comments)
      out << differ.render(render_callback)
    else
      out << differ.render(Gitorious::Diff::InlineTableCallback.new)
    end
    out << "</table>"
    out
  end
  
  def render_sidebyside_diff(udiff)
    differ = Diff::Display::Unified.new(udiff)
    out = %Q{<table class="codediff sidebyside">\n}
    out << %Q{<colgroup class="left"><col class="lines"/><col class="code"/></colgroup>}
    out << %Q{<colgroup class="right"><col class="lines"/><col class="code"/></colgroup>}
    out << %Q{<thead><th class="line-numbers"></th><th></th>}
    out << %Q{<th class="line-numbers"></th><th></th></thead>}
    out << differ.render(Gitorious::Diff::SidebysideTableCallback.new)
    out << "</table>"
    out
  end
  
  def render_diffmode_selector
    out = %Q{<ul class="mode_selector">}
    out << %Q{<li class="list_header">Diff rendering mode:</li>}
    if @diffmode == "sidebyside"
      out << %Q{<li><a href="?diffmode=inline">inline</a></li>}
      out << %Q{<li class="selected">side by side</li>}
    else
      out << %Q{<li class="selected">inline</li>}
      out << %Q{<li><a href="?diffmode=sidebyside">side by side</a></li>}
    end      
    out << "</ul>"
    out
  end
  
  def render_diff_stats(stats)
    out = %Q{<ul class="diff_stats">\n}
    stats.files.each do |filename, adds, deletes, total|
      out << %Q{<li><a href="##{h(filename)}">#{h(filename)}</a>&nbsp;#{total}&nbsp;}
      out << %Q{<small class="deletions">#{(0...deletes).map{|i| "-" }.join}</small>}
      out << %Q{<small class="insertions">#{(0...adds).map{|i| "+" }.join}</small>}
      out << %Q{</li>}
    end
    out << "</ul>\n"
    out
  end

  def render_compact_diff_stats(stats)
    %Q{(<span class="additions">#{stats[:additions].to_s}</span> / } +
      %Q{<span class="deletions">#{stats[:deletions].to_s}</span>)}
  end
end
