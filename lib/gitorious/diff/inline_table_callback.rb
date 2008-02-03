module Gitorious
  module Diff
    class InlineTableCallback < BaseCallback
      def addline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">&nbsp;</td>} + 
        %Q{<td class="line-numbers">#{line.number}</td>} + 
        %Q{<td class="code ins"><ins>#{escape(line)}</ins></td></tr>}
      end
      
      def remline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">#{line.number}</td>} + 
        %Q{<td class="line-numbers">&nbsp;</td>} + 
        %Q{<td class="code del"><del>#{escape(line)}</del></td></tr>}
      end
      
      def modline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">&nbsp;</td>} + 
        %Q{<td class="line-numbers">#{line.number}</td>} + 
        %Q{<td class="code unchanged mod">#{escape(line)}</td></tr>}
      end
      
      def unmodline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">&nbsp;</td>} + 
        %Q{<td class="line-numbers">#{line.number}</td>} + 
        %Q{<td class="code unchanged unmod">#{escape(line)}</td></tr>}
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