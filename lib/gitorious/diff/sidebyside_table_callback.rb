module Gitorious
  module Diff
    class SidebysideTableCallback
      
      # Before blocks
      def before_addblock(block)
        "<tbody><tr>"
      end
      
      def before_remblock(block) 
        "<tbody><tr>"
      end
      
      def before_modblock(block)
        "<tbody><tr>"
      end
      
      def before_unmodblock(block)
        "<tbody><tr>"
      end
      
      def before_sepblock(block)
        "<tbody><tr>"
      end
      
      # After blocks
      def after_addblock(block)
        "</tbody>"
      end
      
      def after_remblock(block)
        "</tbody>"
      end
      
      def after_modblock(block)
        # "</tbody>"
      end
      
      def after_unmodblock(block)
        "</tbody>"
      end
      
      def after_sepblock(block)
        "</body>"
      end
      
      # Before lines
      def before_addline(line)
        # adds go on the right
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code ins"></td>} + 
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code ins"><ins>}
      end
      
      def before_remline(line)
        # rems go on the left (hide the right side)
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code del"><del>#{line}</del></td>} + 
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code del hidden"><del>}
      end
      
      def before_modline(line)
        # TODO: figure how we best display these
        # %Q{<th class="line-numbers">#{line.number}</th>} + 
        # %Q{<td class="code changed mod">#{line}</td>} + 
        # %Q{<th class="line-numbers">#{line.number}</th>} + 
        # %Q{<td class="code changed mod">}
      end
      
      def before_unmodline(line)
        # unmods goes on both sides
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code unchanged unmod">#{line}</td>} + 
        %Q{<th class="line-numbers">#{line.number}</th>} + 
        %Q{<td class="code unchanged unmod">}
      end
      
      def before_sepline(line)
        %Q{<th class="line-numbers line-num-cut">...</th>} + 
        %Q{<td class="code cut-line">...</td>} + 
        %Q{<th class="line-numbers line-num-cut">...</th>} + 
        %Q{<td class="code cut-line">}
      end
      
      # After lines
      def after_addline(line)
        "</ins></td></tr>"
      end
      
      def after_remline(line)
        "</del></td></tr>"
      end
      
      def after_modline(line)
        # "</td></tr>"
      end
      
      def after_unmodline(line)
        "</td></tr>"
      end
      
      def after_sepline(line)
        "</td></tr>"
      end
      
      def new_line
      end
    end
  end
end