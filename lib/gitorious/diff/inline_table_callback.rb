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

module Gitorious
  module Diff
    class InlineTableCallback < BaseCallback      
      def addline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">#{line.old_number}</td>} + 
        %Q{<td class="line-numbers">#{line.new_number}</td>} + 
        %Q{<td class="code ins"><ins>} +
          render_line(line) +
        %Q{</ins></td></tr>}
      end
      
      def remline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">#{line.old_number}</td>} + 
        %Q{<td class="line-numbers">#{line.new_number}</td>} + 
        %Q{<td class="code del"><del>} + 
          render_line(line) + 
        %Q{</del></td></tr>}
      end
      
      def modline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">#{line.old_number}</td>} + 
        %Q{<td class="line-numbers">#{line.new_number}</td>} + 
        %Q{<td class="code unchanged mod">#{render_line(line)}</td></tr>}
      end
      
      def unmodline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">#{line.old_number}</td>} + 
        %Q{<td class="line-numbers">#{line.new_number}</td>} + 
        %Q{<td class="code unchanged unmod">#{render_line(line)}</td></tr>}
      end
      
      def sepline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers line-num-cut">&hellip;</td>} + 
        %Q{<td class="line-numbers line-num-cut">&hellip;</td>} + 
        %Q{<td class="code cut-line"></td></tr>}
      end
    end
  end
end