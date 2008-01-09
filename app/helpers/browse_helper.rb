module BrowseHelper
  
  def browse_path
    project_repository_browse_path(@project, @repository)
  end
  
  def tree_path(sha1=nil)
    project_repository_tree_path(@project, @repository, sha1)    
  end
  
  def commit_path(sha1)
    project_repository_commit_path(@project, @repository, sha1)    
  end
  
  def blob_path(sha1, filename)
    project_repository_blob_path(@project, @repository, sha1, filename)    
  end
  
  def raw_blob_path(sha1, filename)
    project_repository_raw_blob_path(@project, @repository, sha1, filename)    
  end
  
  def diff_path(sha1, other_sha1)
    project_repository_diff_path(@project, @repository, sha1, other_sha1)    
  end
    
  def render_tag_box_if_match(sha, tags_per_sha)
    tags = tags_per_sha[sha]
    return if tags.blank?
    out = ""
    tags.each do |tagname|
      out << %Q{<span class="tag"><code>}
      out << tagname
      out << %Q{</code></span>}
    end
    out
  end  
  
  # Takes a unified diff as input and renders it as html
  # this is the crappy one from collaboa
  # TODO: finish up the proper OO one
   def render_diff(udiff, src_sha, dst_sha)
     return if udiff.blank?
     out = "<table class=\"codediff\">\n"

     lines = udiff.split("\n")
     lines.reject!{ |line| line =~ /^new file mode [0-9]+/ }

     lines_that_differs = /@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@/

     out << "<thead>\n"
     out << %Q{\t<tr><td class="line-numbers">#{src_sha}</td>}
     out << %Q{<td class="line-numbers">#{dst_sha}</td><td>&nbsp</td></tr>\n}
     out << "</thead>\n"

     prev_counter = 0
     cur_counter = 0
     change_num = 0

     lines[4..lines.length].each do |line|      
       if line_nums = line.match(lines_that_differs)      
       	prev_line_numbers = line_nums[1].to_i...(line_nums[1].to_i + (line_nums[2]).to_i)
         cur_line_numbers = line_nums[3].to_i...(line_nums[3].to_i + (line_nums[4]).to_i)
         prev_counter = prev_line_numbers.first - 1
         cur_counter = cur_line_numbers.first - 1
         change_num += 1 
       end

       line = h(line)
       line.gsub!(/^\s/, '') # The column where + or - would be
       line.gsub!(/^(\+{1}(\s+|\t+)?(.*))/, '\2<ins>\3</ins>')
       line.gsub!(/^(-{1}(\s+|\t+)?(.*))/, '\2<del>\3</del>')
       #line.gsub!('\ No newline at end of file', '')

       out << "<tr class=\"changes\">\n"

       if line.match(/^(\s+|\t+)?<del>/) 
         out << "\t<td class=\"line-numbers\">" + prev_counter.to_s + "</td>\n"
         out << "\t<td class=\"line-numbers\">&nbsp;</td>\n"
         prev_counter += 1
         action_class = 'del'
       elsif line.match(/^(\s+|\t+)?<ins>/)
         out << "\t<td class=\"line-numbers\">&nbsp;</td>\n"
         out << "\t<td class=\"line-numbers\">" + cur_counter.to_s + "</td>\n"
         cur_counter += 1 
         action_class = 'ins'
       else
         if line.match(lines_that_differs)
           line = ''
           if change_num > 1
             out << "\t<td class=\"line-numbers line-num-cut\">...</td>\n"
             out << "\t<td class=\"line-numbers line-num-cut\">...</td>\n"
             action_class = 'cut-line'
           else 
             out << "\t<td class=\"line-numbers\"></td>\n"
             out << "\t<td class=\"line-numbers\"></td>\n"
             action_class = 'unchanged'
           end
         else
           out << "\t<td class=\"line-numbers\"></td>\n"
           out << "\t<td class=\"line-numbers\"></td>\n"
           action_class = 'unchanged'
         end
         prev_counter += 1 
         cur_counter += 1 
       end

       out << "\t<td class=\"code #{action_class}\">" + line + "</td></tr>\n"     
     end
     out << "\n</table>\n"
   end
  
end
