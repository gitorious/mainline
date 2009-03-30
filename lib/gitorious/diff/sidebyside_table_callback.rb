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

module Gitorious
  module Diff
    class SidebysideTableCallback < BaseCallback
      
      # Before blocks
      def before_addblock(block)
        %q{<tbody class="add"><tr>}
      end
      
      def before_remblock(block) 
        %Q{<tbody class="rem"><tr>}
      end
      
      def before_modblock(block)
        %Q{<tbody class="mod"><tr>}
      end
      
      def before_unmodblock(block)
        %Q{<tbody class="unmod"><tr>}
      end
      
      def before_sepblock(block)
        %Q{<tbody class="sep"><tr>}
      end
      
      # After blocks
      def after_addblock(block)
        "</tbody>"
      end
      
      def after_remblock(block)
        "</tbody>"
      end
      
      def after_modblock(block)
        "</tbody>"
      end
      
      def after_unmodblock(block)
        "</tbody>"
      end
      
      def after_sepblock(block)
        "</tbody>"
      end
      
      # Before lines
      def addline(line)
        # adds go on the right
        %Q{<th class="line-numbers">#{line.old_number}</th>} + 
        %Q{<td class="code ins"></td>} + 
        %Q{<th class="line-numbers">#{line.new_number}</th>} + 
        %Q{<td class="code ins"><ins>#{render_line(line)}</ins></td></tr>}
      end
      
      def remline(line)
        # rems go on the left (hide the right side)
        %Q{<th class="line-numbers">#{line.old_number}</th>} + 
        %Q{<td class="code del"><del>#{render_line(line)}</del></td>} + 
        %Q{<th class="line-numbers">#{line.new_number}</th>} + 
        %Q{<td class="code del hidden"><del>#{render_line(line)}</del></td></tr>}
      end
      
      def modline(line)
        # TODO: figure how we best display these
        # %Q{<th class="line-numbers">#{line.old_number}</th>} + 
        # %Q{<td class="code changed mod">#{render_line(line)}</td>} + 
        # %Q{<th class="line-numbers">#{line.new_number}</th>} + 
        # %Q{<td class="code changed mod">#{render_line(line)}</td></tr>}
      end
      
      def unmodline(line)
        # unmods goes on both sides
        %Q{<th class="line-numbers">#{line.old_number}</th>} + 
        %Q{<td class="code unchanged unmod">#{render_line(line)}</td>} + 
        %Q{<th class="line-numbers">#{line.new_number}</th>} + 
        %Q{<td class="code unchanged unmod">#{render_line(line)}</td></tr>}
      end
      
      def sepline(line)
        %Q{<th class="line-numbers line-num-cut">&hellip;</th>} + 
        %Q{<td class="code cut-line"></td>} + 
        %Q{<th class="line-numbers line-num-cut">&hellip;</th>} + 
        %Q{<td class="code cut-line"></td></tr>}
      end
      
      def nonewlineline(line)
        %Q{<th class="line-numbers line-num-cut">&hellip;</th>} + 
        %Q{<td class="code mod"></td>} + 
        %Q{<th class="line-numbers line-num-cut">&hellip;</th>} + 
        %Q{<td class="code mod">#{line}</td></tr>}
      end
    end
  end
end