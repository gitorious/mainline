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
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code ins"></td>} + 
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code ins"><ins>#{escape(line)}</ins></td></tr>}
      end
      
      def remline(line)
        # rems go on the left (hide the right side)
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code del"><del>#{CGI.escapeHTML(line)}</del></td>} + 
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code del hidden"><del>#{escape(line)}</del></td></tr>}
      end
      
      def modline(line)
        # TODO: figure how we best display these
        # %Q{<th class="line-numbers">#{line.number}</th>} + 
        # %Q{<td class="code changed mod">#{CGI.escapeHTML(line)}</td>} + 
        # %Q{<th class="line-numbers">#{line.number}</th>} + 
        # %Q{<td class="code changed mod">#{escape(line)}</td></tr>}
      end
      
      def unmodline(line)
        # unmods goes on both sides
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code unchanged unmod">#{escape(line)}</td>} + 
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code unchanged unmod">#{escape(line)}</td></tr>}
      end
      
      def sepline(line)
        %Q{<th class="line-numbers line-num-cut">&hellip;</th>} + 
        %Q{<td class="code cut-line"></td>} + 
        %Q{<th class="line-numbers line-num-cut">&hellip;</th>} + 
        %Q{<td class="code cut-line"></td></tr>}
      end
    end
  end
end