module CommitsHelper
  include RepositoriesHelper
  
  # Takes a unified diff as input and renders it as html
  def render_diff(udiff, display_mode = "inline")
    return if udiff.blank?

    case display_mode
    when "sidebyside"
      render_sidebyside_diff(udiff)
    else
      render_inline_diff(udiff)
    end
  end
  
  #diff = Diff::Display::Unified.new(load_diff("simple"))
  #diff.render(Diff::Renderer::Base.new)
  def render_inline_diff(udiff)
    differ = Diff::Display::Unified.new(udiff)
    out = %Q{<table class="codediff inline">\n}
    out << "<thead>\n"
    out << "<tr>"
    out << %Q{<td class="line-numbers"></td>}
    out << %Q{<td class="line-numbers"></td>}
    out << "<td>&nbsp</td></tr>\n"
    out << "</thead>\n"
    out << differ.render(Gitorious::Diff::InlineTableCallback.new)
    out << %Q{<tr class="toggle_diff"><td colspan="3">}
    out << %Q{<small>#{link_to_function "toggle raw diff", "$('diff#{udiff.object_id}').toggle()"}</small></td></tr>}
    out << %Q{<tr class="raw_diff"><td colspan="3" style="display:none" id="diff#{udiff.object_id}">}
    out << %Q{<pre>#{h(udiff)}</pre>}
    out << "</td></tr>"
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
    out << %Q{<tr class="toggle_diff"><td colspan="4">}
    out << %Q{<small>#{link_to_function "toggle raw diff", "$('diff#{udiff.object_id}').toggle()"}</small></td></tr>}
    out << %Q{<tr class="raw_diff"><td colspan="4" style="display:none" id="diff#{udiff.object_id}">}
    out << %Q{<pre>#{h(udiff)}</pre>}
    out << "</td></tr>"
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
    stats.files.each_pair do |filename, stats|
      total = stats[:insertions] + stats[:deletions]
      out << %Q{<li><a href="##{h(filename)}">#{h(filename)}</a>&nbsp;#{total}&nbsp;}
      out << %Q{<small class="deletions">#{(0...stats[:deletions]).map{|i| "-" }}</small>}
      out << %Q{<small class="insertions">#{(0...stats[:insertions]).map{|i| "+" }}</small>}
      out << %Q{</li>}
    end
    out << "</ul>\n"
    out
  end
end
