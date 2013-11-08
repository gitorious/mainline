# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require "gitorious/diff/base_callback"
require "gitorious/diff/inline_table_callback"
require "gitorious/diff/sidebyside_table_callback"

module DiffHelper
  def sidebyside_diff?
    @diffmode == "sidebyside"
  end

  # Supply a block that fetches an array of comments with the file path as parameter
  def render_inline_diffs_with_stats(file_diffs, state = :closed)
    file_diffs.map do |file|
      a_path = file.a_path.force_utf8
      diff_renderer = Diff::Display::Unified.new(file.diff)
      out =  %Q{<div class="file-diff" data-diff-path="#{a_path}">}
      out << %Q{<div class="header round-top-10 #{state == :closed ? 'closed' : 'open'}">}
      commit_link = if @commit
                      link_to_if(@commit, "#{h(a_path)}", blob_path(@commit.id, a_path).sub("%2F","/"))
                    else
                      h(a_path)
                    end
      out << %Q{<span class="title"><span class="icon"></span>#{commit_link}</span>}
      out << %Q{<div class="diff-stats">}
      out << render_compact_diff_stats(diff_renderer.stats)
      out << "</div></div>"
      out << %Q{<div class="diff-hunks" #{state == :closed ? 'style="display:none"' : ''}>}

      if file.diff[0..256].include?("\000")
        out << "Binary files differ"
      else
        diff_options = {}
        diff_options[:comments] = if block_given?
                                    yield(file)
                end
        out << render_inline_diff(file.diff, diff_renderer, diff_options).force_utf8
      end
      out << "</div></div>"
      out
    end.join("\n").html_safe
  end

  def render_inline_diffs_controls(cookie_prefix)
    (<<-HTML).html_safe
      <div class="file-diff-controls">
        <small>
          <a href="#" id="expand-all" gts:cookie-prefix="#{cookie_prefix}">expand all</a> /
          <a href="#" id="collapse-all" gts:cookie-prefix="#{cookie_prefix}">collapse all</a>
        </small>
     </div>
    HTML
  end

  def render_inline_diff(udiff, differ = nil, options = {})
    differ ||= Diff::Display::Unified.new(udiff)
    out = %Q{<table class="codediff inline">\n}
    out << "<thead>\n"
    out << %Q{<tr><td class="inline_comments">&nbsp;</td>}
    out << %Q{<td class="line-numbers"></td>}
    out << %Q{<td class="line-numbers"></td>}
    out << "<td>&nbsp</td></tr>\n"
    out << "</thead>\n"
    if comments = options[:comments]
      render_callback = Gitorious::Diff::InlineTableCallback.with_comments(comments, self)
      out << differ.render(render_callback)
    else
      out << differ.render(Gitorious::Diff::InlineTableCallback.new)
    end
    out << "</table>"
    out.html_safe
  end

  def render_diffmode_selector(repository, commit, mode)
    project = repository.project
    render_diffmode_selector_plain(repository, mode) do
      <<-HTML.html_safe
       <li><a href="#{project_repository_commit_path(project, repository, commit.id, :format => :diff)}">Raw diff</a></li>
       <li><a href="#{project_repository_commit_path(project, repository, commit.id, :format => :patch)}">Raw patch</a></li>
      HTML
    end
  end

  def render_diffmode_selector_plain(repository, mode)
    links = ""

    if mode == :sidebyside
      links += "<li><a href=\"#{url_for(:diffmode => :inline)}\">Inline diffs</a></li>"
      links += "<li class=\"active\"><a>Side by side diffs</a></li>"
    else
      links += "<li class=\"active\"><a>Inline diffs</a></li>"
      links += "<li><a href=\"#{url_for(:diffmode => :sidebyside)}\">Side by side diffs</a></li>"
    end

    <<-HTML.html_safe
      <ul class="nav nav-tabs">
        #{links}
        #{yield if block_given?}
      </ul>
    HTML
  end

  def render_diff_stats(stats)
    content_tag(:ul, :class => 'gts-diff-summary') {
      stats.files.map { |filename, adds, deletes, total|
        del = (0...deletes).map { |i| "-" }.join
        ins = (0...adds).map{ |i| "+" }.join
        content_tag(:li) {
          inner =  "<a href=\"##{h(filename)}\">#{h(filename)}</a> (#{total}) "
          inner << "<span class=\"gts-diff-rm\">#{del}</span>"
          inner << "<span class=\"gts-diff-add\">#{ins}</span>"
          inner.html_safe
        }
      }.join.html_safe
    }.html_safe
  end

  def render_compact_diff_stats(stats)
    ("(<span class=\"additions\">#{stats[:additions].to_s}</span> / " +
     "<span class=\"deletions\">#{stats[:deletions].to_s}</span>)").html_safe
  end
end
