module Diff::Display
  # Processes the diff and generates a Data object which contains the
  # resulting data structure.
  #
  # The +run+ class method is fed a diff and returns a Data object. It will
  # accept as its argument a String, an Array or a File object (or anything 
  # that responds to #each):
  #
  #   Diff::Display::Unified::Generator.run(diff)
  #
  class Unified::Generator
    
    # Extracts the line number info for a given diff section
    LINE_NUM_RE = /^@@ [+-]([0-9]+)(?:,([0-9]+))? [+-]([0-9]+)(?:,([0-9]+))? @@/
    LINE_TYPES  = {'+' => :add, '-' => :rem, ' ' => :unmod}
    
    # Runs the generator on a diff and returns a Data object
    def self.run(udiff)
      raise ArgumentError, "Object must be enumerable" unless udiff.respond_to?(:each)
      generator = new
      udiff.each {|line| generator.process(line.chomp)}
      generator.data
    end
    
    def initialize
      @buffer         = []
      @prev_buffer    = []
      @line_type      = nil
      @prev_line_type = nil
      @offset         = [0, 0]
      @data = Data.new
      self
    end
    
    # Finishes up with the generation and returns the Data object (could
    # probably use a better name...maybe just #data?)
    def data
      close
      @data
    end
    
    # Operates on a single line from the diff and passes along the
    # collected data to the appropriate method for further processing. The
    # cycle of processing is in general:
    #
    #   process --> identify_block --> process_block --> process_line 
    #    
    def process(line)      
      if is_header_line?(line)
        identify_block
        push Block.header
        current_block << Line.header(line)
        return
      end
      
      if line =~ LINE_NUM_RE
        identify_block
        push Block.header
        current_block << Line.header(line)
        add_separator unless @offset[0].zero?
        @line_type = nil
        @offset    = Array.new(2) { $3.to_i - 1 }
        return
      end
      
      new_line_type, line = LINE_TYPES[car(line)], cdr(line)
      
      # Add line to the buffer if it's the same diff line type
      # as the previous line
      # 
      # e.g. 
      #
      #   + This is a new line
      #   + As is this one
      #   + And yet another one...
      #
      if new_line_type.eql?(@line_type)
        @buffer.push(line)
      else
        identify_block
        @buffer = [line]
        @line_type = new_line_type
      end
      
    end
    
    protected
      def is_header_line?(line)
        return true if ['+++ ', '--- '].include?(line[0,4])
        return true if line =~ /^(new|delete) file mode [0-9]+$/
        return true if line =~ /^diff \-\-git/
        return true if line =~ /^index \w+\.\.\w+ [0-9]+$/
        false
      end
      
      def identify_block
        if LINE_TYPES.values.include?(@line_type)
          process_block(@line_type)
        end

        @prev_line_type = nil
      end
      
      def process_block(diff_line_type)
        push Block.send(diff_line_type)
        unroll_buffer
      end

      def add_separator
        push SepBlock.new 
        current_block << SepLine.new 
      end

      def extract_change(line, start, ending)
        line.size > (start - ending) ? line[start...ending] : ''
      end

      def car(line)
        line[0,1]
      end

      def cdr(line)
        line[1..-1]
      end

      # Returns the current Block object
      def current_block
        @data.last
      end

      # Adds a Line object onto the current Block object 
      def push(line)
        @data.push line
      end

      def prev_buffer
        @prev_buffer
      end

      def unroll_buffer
        return if @buffer.empty?
        @buffer.each do |line| 
          case @line_type
            when :add
              @offset[1] += 1
              current_block << Line.send(@line_type, line, @offset[1])
            when :rem
              @offset[0] += 1
              current_block << Line.send(@line_type, line, @offset[0])
            when :unmod
              @offset[0] += 1
              @offset[1] += 1
              current_block << Line.send(@line_type, line, *@offset)
          end
        end
      end

      # This method is called once the generator is done with the unified
      # diff. It is a finalizer of sorts. By the time it is called all data
      # has been collected and processed.
      def close
        # certain things could be set now that processing is done
        identify_block
      end

      # Determines the extent of differences between two string. Returns
      # an array containing the offset at which changes start, and then 
      # negative offset at which the chnages end. If the two strings have
      # neither a common prefix nor a common suffic, [0, 0] is returned.
      def get_change_extent(str1, str2)
        start = 0
        limit = [str1.size, str2.size].sort.first
        while start < limit and str1[start, 1] == str2[start, 1]
          start += 1
        end
        ending = -1
        limit -= start
        while -ending <= limit and str1[ending, 1] == str2[ending, 1]
          ending -= 1
        end

        return [start, ending + 1]
      end
  end
end