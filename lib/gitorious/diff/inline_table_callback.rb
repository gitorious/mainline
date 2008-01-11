module Gitorious
  module Diff
    class InlineTableCallback
      
      # Before blocks
      def before_addblock(block)
      end
      
      def before_remblock(block) 
      end
      
      def before_modblock(block)
      end
      
      def before_unmodblock(block)
      end
      
      def before_sepblock(block)
      end
      
      # After blocks
      def after_addblock(block)
      end
      
      def after_remblock(block)
      end
      
      def after_modblock(block)
      end
      
      def after_unmodblock(block)
      end
      
      def after_sepblock(block)
      end
      
      # Before lines
      def before_addline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">&nbsp;</td>} + 
        %Q{<td class="line-numbers">#{line.number}</td>} + 
        %Q{<td class="code ins"><ins>}
      end
      
      def before_remline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">#{line.number}</td>} + 
        %Q{<td class="line-numbers">&nbsp;</td>} + 
        %Q{<td class="code del"><del>}
      end
      
      def before_modline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">&nbsp;</td>} + 
        %Q{<td class="line-numbers">#{line.number}</td>} + 
        %Q{<td class="code unchanged mod">}
      end
      
      def before_unmodline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers">&nbsp;</td>} + 
        %Q{<td class="line-numbers">#{line.number}</td>} + 
        %Q{<td class="code unchanged unmod">}
      end
      
      def before_sepline(line)
        %Q{<tr class="changes">} + 
        %Q{<td class="line-numbers line-num-cut">...</td>} + 
        %Q{<td class="line-numbers line-num-cut">...</td>} + 
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
       "</td></tr>"
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