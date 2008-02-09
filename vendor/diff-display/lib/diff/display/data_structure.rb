module Diff
  module Display
    class Data < Array
      def initialize
        super
      end
      
      def to_diff
        diff = ""
        each do |block|
          block.each do |line|
            case line
            when HeaderLine
              diff << "#{line}\n"
            when UnModLine
              diff << " #{line}\n"
            when SepLine
              diff << "\n"
            when AddLine
              diff << "+#{line}\n"
            when RemLine
              diff << "-#{line}\n"
            end
          end
        end
        diff.chomp
      end
    end
    
    # Every line from the passed in diff gets transformed into an instance of
    # one of line Line class's subclasses. One subclass exists for each line
    # type in a diff. As such there is an AddLine class for added lines, a RemLine
    # class for removed lines, an UnModLine class for lines which remain unchanged and
    # a SepLine class which represents all the lines that aren't part of the diff.
    class Line < String
      class << self
        def add(line, line_number)
          AddLine.new(line, line_number)
        end
      
        def rem(line, line_number)
          RemLine.new(line, line_number)
        end
      
        def unmod(line, line_number)
          UnModLine.new(line, line_number)
        end
        
        def header(line)
          HeaderLine.new(line)
        end
      end
      
      def initialize(line, line_number)
        super(line)
        @number = line_number
      end
      attr_reader :number
      
      def inspect
        %Q{#<#{self.class.name} [#{number.inspect}] "#{self}">}
      end
    end
    
    class AddLine < Line
      def initialize(line, line_number)
        super(line, line_number)
      end
    end
    
    class RemLine < Line
      def initialize(line, line_number)
        super(line, line_number)
      end
    end
    
    class UnModLine < Line
      def initialize(line, line_number)
        super(line, line_number)
      end
    end
    
    class SepLine < Line
      def initialize(line = '...')
        super(line, nil)
      end
    end
    
    class HeaderLine < Line
      def initialize(line)
        super(line, nil)
      end
    end
    
    # This class is an array which contains Line objects. Just like Line
    # classes, several Block classes inherit from Block. If all the lines
    # in the block are added lines then it is an AddBlock. If all lines
    # in the block are removed lines then it is a RemBlock. If the lines
    # in the block are all unmodified then it is an UnMod block. If the
    # lines in the block are a mixture of added and removed lines then
    # it is a ModBlock. There are no blocks that contain a mixture of
    # modified and unmodified lines.
    class Block < Array
      class << self
        def add;    AddBlock.new    end 
        def rem;    RemBlock.new    end
        def mod;    ModBlock.new    end
        def unmod;  UnModBlock.new  end
        def header; HeaderBlock.new end
      end
    end

    #:stopdoc:#
    class AddBlock    < Block;  end  
    class RemBlock    < Block;  end
    class ModBlock    < Block;  end
    class UnModBlock  < Block;  end
    class SepBlock    < Block;  end
    class HeaderBlock < Block;  end
    #:startdoc:#
  end
end