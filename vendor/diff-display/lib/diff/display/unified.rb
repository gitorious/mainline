module Diff #:nodoc:#
  module Display #:nodoc:#
    # = Diff::Display::Unified
    #
    # Diff::Display::Unified is meant to make dealing with the presentation of
    # diffs easy, customizable and succinct. It breaks a diff up into sections,
    # or blocks, which are defined by the types of lines they contain. If, for
    # example, there is a section where five lines have been added then an
    # AddBlock is created and those five lines are placed into that AddBlock.
    # The design is quite simple: The generated object is made up of Block 
    # objects which are themselves made up of Line objects. 
    #
    # === Blocks
    #
    # Blocks represent various sections that one finds in a diff.
    # There are five different Block classes:
    #   
    # [AddBlock]
    #   Contains only instances of AddLine
    #
    # [RemBlock]
    #   Contains only instances of RemLine
    #
    # [ModBlock]
    #   Contains a set of RemLine objects followed by a set of AddLine
    #   objects
    #
    # [UnModBlock]
    #   Contains instances of UnModLine which represent sets of context lines
    #   that are unchanged in both the old and modified data set that
    #   surround Mod, Add or Rem blocks
    #
    # [SepBlock]
    #   Contains a single SepLine. SepBlocks are placed between blocks when
    #   the distances between one modification set and the next exceeds the
    #   number of context buffer surrounding them.
    #
    # === Lines
    #
    # The Line classes are much line the Block classes, just on a smaller
    # scale. 
    #
    # There are 4 lines classes:
    #
    # === Example
    # 
    # Consider the following before and after on a diff.
    #
    # Before:
    #
    #   -  class OldName < Array
    #   +  class NewName < Array
    #
    #   -    def initialize(boundry)
    #   -      @boundry = boundry
    #   -    end
    #   -
    #        def stay(the, same)
    #   +    end
    #   +
    #   +    def all_new
    #   +      @this, @method = *IS_ALL_NEW
    #
    # After:
    #
    #   ---------------------------------------- ModBlock
    #       1 [RemLine]  class OldName < Array
    #       1 [AddLine]  class NewName < Array
    #   ----------------------------------------
    #
    #   ---------------------------------------- UnModBlock
    #       2 [UnModLine]
    #   ----------------------------------------
    #
    #   ---------------------------------------- RemBlock
    #       3 [RemLine]    def initialize(boundry)
    #       4 [RemLine]      @boundry = boundry
    #       5 [RemLine]    end
    #       6 [RemLine]
    #   ----------------------------------------
    #
    #   ---------------------------------------- UnModBlock
    #       7 [UnModLine]    def stay(the, same)
    #   ----------------------------------------
    #
    #   ---------------------------------------- AddBlock
    #       8 [AddLine]    end
    #       9 [AddLine]
    #      10 [AddLine]    def all_new
    #      11 [AddLine]      @this, @method = -IS_ALL_NEW
    #   ----------------------------------------
    #
    # Note: That is just a representation of the structure of the generated
    # object. Also note that this example does not include any SepBlocks since
    # the changes in the example diff are all contiguous.
    #
    # Internally the datastructure is quite simple: The Data object has an
    # array of Block objects which themselves have an array of Line
    # objects. Traversing the object on the block level or line level is
    # equally simple so you can focus on what to do for each type of block and
    # line.
    module Unified
      # Every line from the passed in diff gets transformed into an instance of
      # one of line Line class's subclasses. One subclass exists for each line
      # type in a diff. As such there is an AddLine class for added lines, a RemLine
      # class for removed lines, an UnModLine class for lines which remain unchanged and
      # a SepLine class which represents all the lines that aren't part of the diff.
      class Line < String
        def initialize(line, line_number)
          super(line)
          @line_number = line_number
          self
        end

        def contains_inline_change?
          @inline
        end

        # Returns the line number of the diff line
        def number
          @line_number
        end

        def decorate(&block)
          yield self
        end

        protected 

          def inline_add_open;  '' end
          def inline_add_close; '' end
          def inline_rem_open;  '' end
          def inline_rem_close; '' end

          def escape
            self
          end

          def expand
            escape.gsub("\t", ' ' * tabwidth).gsub(/ ( +)|^ /) do |match|
              (space + ' ') * (match.size / 2) + 
               space        * (match.size % 2)
            end
          end

          def tabwidth
            4
          end


          def space
            ' '
          end

        class << self
          def add(line, line_number, inline = false)
            AddLine.new(line, line_number, inline)
          end

          def rem(line, line_number, inline = false)
            RemLine.new(line, line_number, inline)
          end

          def unmod(line, line_number)
            UnModLine.new(line, line_number)
          end
        end
      end

      class AddLine < Line #:nodoc:#
        def initialize(line, line_number, inline = false)
          line = inline ? line % [inline_add_open, inline_add_close] : line
          super(line, line_number)
          @inline = inline
          self
        end
      end

      class RemLine < Line #:nodoc:#
        def initialize(line, line_number, inline = false)
          line = inline ? line % [inline_rem_open, inline_rem_close] : line
          super(line, line_number)
          @inline = inline
          self
        end
      end

      class UnModLine < Line #:nodoc:#
        def initialize(line, line_number)
          super(line, line_number)
        end
      end

      class SepLine < Line #:nodoc:#
        def initialize(line = '...')
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
        def initialize
          super
        end

        def <<(line_object)
          super(line_object)
          self
        end

        def decorate(&block)
          yield self
        end

        class << self
          def add;   AddBlock.new   end 
          def rem;   RemBlock.new   end
          def mod;   ModBlock.new   end
          def unmod; UnModBlock.new end
        end
      end

      #:stopdoc:#
      class AddBlock   < Block;   end  
      class RemBlock   < Block;   end
      class ModBlock   < Block;   end
      class UnModBlock < Block;   end
      class SepBlock   < Block;   end
      #:startdoc:#

      # A Data object contains the generated diff data structure. It is an
      # array of Block objects which are themselves arrays of Line objects. The
      # Generator class returns a Data instance object after it is done
      # processing the diff.
      class Data < Array
        def initialize
          super
        end

        def debug
          demodularize = Proc.new {|obj| obj.class.name[/\w+$/]}
          each do |diff_block|
            print "-" * 40, ' ', demodularize.call(diff_block)
            puts
            puts diff_block.map {|line| 
              "%5d" % line.number             + 
              " [#{demodularize.call(line)}]" +
              line
            }.join("\n")
            puts "-" * 40, ' ' 
          end
        end

      end

      # Processes the diff and generates a Data object which contains the
      # resulting data structure.
      #
      # The +run+ class method is fed a diff and returns a Data object. It will
      # accept as its argument a String, an Array or a File object:
      #
      #   Diff::Display::Unified::Generator.run(diff)
      #
      class Generator

        # Extracts the line number info for a given diff section
        LINE_NUM_RE = /@@ [+-]([0-9]+),([0-9]+) [+-]([0-9]+),([0-9]+) @@/
        LINE_TYPES  = {'+' => :add, '-' => :rem, ' ' => :unmod}

        class << self

          # Runs the generator on a diff and returns a Data object without
          # instantiating a Generator object
          def run(udiff)
            raise ArgumentError, "Object must be enumerable" unless udiff.respond_to?(:each)
            generator = new
            udiff.each {|line| generator.process(line.chomp)}
            generator.data
          end
        end

        def initialize
          @buffer         = []
          @prev_buffer    = []
          @line_type      = nil
          @prev_line_type = nil
          @offset_base    = 0
          @offset_changed = 0
          @data           = Diff::Display::Unified::Data.new
          self
        end

        # Operates on a single line from the diff and passes along the
        # collected data to the appropriate method for further processing. The
        # cycle of processing is in general:
        #
        #   process --> identify_block --> process_block --> process_line 
        #
        def process(line)
          return if is_extra_header_line?(line)
          
          if match = LINE_NUM_RE.match(line) 
            identify_block
            add_separator unless @offset_changed.zero?
            @line_type      = nil
            @offset_base    = match[1].to_i - 1
            @offset_changed = match[3].to_i - 1
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
            # Side by side inline diff
            #
            # e.g.
            #
            #   - This line just had to go
            #   + This line is on the way in
            #
            if new_line_type.eql?(LINE_TYPES['+']) and @line_type.eql?(LINE_TYPES['-'])
              @prev_buffer = @buffer
              @prev_line_type = @line_type
            else
              identify_block
            end
            @buffer = [line]
            @line_type = new_line_type
          end
        end

        # Finishes up with the generation and returns the Data object (could
        # probably use a better name...maybe just #data?)
        def data
          close
          @data
        end

        protected 
        
          def is_extra_header_line?(line)
            return true if ['++', '--'].include?(line[0,2])
            return true if line =~ /^(new|delete) file mode [0-9]+$/
            return true if line =~ /^diff \-\-git/
            return true if line =~ /^index \w+\.\.\w+ [0-9]+$/
            false
          end

          def identify_block
            if @prev_line_type.eql?(LINE_TYPES['-']) and @line_type.eql?(LINE_TYPES['+'])
              process_block(:mod, true, true)
            else
              if LINE_TYPES.values.include?(@line_type)
                process_block(@line_type, true)
              end
            end

            @prev_line_type = nil
          end

          def process_block(diff_line_type, new = false, old = false)
            push Block.send(diff_line_type)
            # Mod block
            if diff_line_type.eql?(:mod) && @prev_buffer.size && @buffer.size == 1
              process_line(@prev_buffer.first, @buffer.first)
              return
            end
            unroll_prev_buffer if old
            unroll_buffer      if new 
          end

          # TODO Needs a better name...it does process a line (two in fact) but
          # its primary function is to add a Rem and an Add pair which
          # potentially have inline changes
          def process_line(oldline, newline)
            start, ending = get_change_extent(oldline, newline)

            # -
            line = inline_diff(oldline, start, ending)
            current_block << Line.rem(line, @offset_base += 1, true)

            # +
            line = inline_diff(newline, start, ending)
            current_block << Line.add(line, @offset_changed += 1, true)
          end

          # Inserts string formating characters around the section of a string
          # that differs internally from another line so that the Line class
          # can insert the desired formating
          def inline_diff(line, start, ending)
            line[0, start] + 
            '%s' + extract_change(line, start, ending) + '%s' + 
            line[ending, ending.abs]
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

          def unroll_prev_buffer
            return if @prev_buffer.empty?
            @prev_buffer.each  do |line| 
              @offset_base += 1 
              current_block << Line.send(@prev_line_type, line, @offset_base)
            end
          end

          def unroll_buffer
            return if @buffer.empty?
            @buffer.each do |line| 
              @offset_changed += 1 
              current_block << Line.send(@line_type, line, @offset_changed)
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

      # The Renderer class is the single point of entry for the
      # Diff::Display::Unified library. It can be used in two ways. One is to
      # create a new instance which returns a Data object created by the
      # Generator. This object contains the collections of Blocks and Lines
      # which the user can iterate over.
      #
      #   data_object = Diff::Display::Unified::Renderer.new(diff)
      #
      # The second way is to call the Renderer's +run+ class method, optionally
      # passing in an instance of a class which inherits from
      # Diff::Display::Unified::Callbacks. This then calls the +render+ method
      # which uses the methods defined in the callback class instance to
      # decorate the diff contents as it unrolls the Data object.
      #
      # Somewhere up above:
      #
      #   class MyDiffCallbacks < Diff::Display::Unified::Callbacks
      #
      #     def before_addline '<ins>'  end
      #     def after_addline  '</ins>' end
      #
      #   end
      #
      #   callback_obj = MyDiffCallbacks.new
      #
      #   fully_rendered_diff = Diff::Display::Unified::Renderer.run(diff, callback_obj)
      #
      class Renderer
        attr_reader :data

        def initialize(diff, callback_object = nil)
          @callbacks = callback_object || Diff::Display::Unified::Callbacks.new
          @data = Diff::Display::Unified::Generator.run(diff)
        end

        # XXX The relationship between render and rendered and run is too complicated
        # and nuanced
        def render
          @rendered = @data.inject([]) do |block_data, block|
            block_data << before_method(block)
            # Block must use braces rather than do/end due to precedence rules!
            block_data.concat block.inject([]) { |line_data, line|
              line_data << before_method(line) << escape(line) << after_method(line)
            }
            block_data << after_method(block)
          end
        end

        def rendered
          (@rendered ? @rendered : render).join(new_line)
        end

        class << self
          def run(diff, callback_object = nil)
            new(diff, callback_object).rendered
          end
        end
        
        def escape(text)
          text
        end

        private
          
          def class_name(object)
            object.class.name[/\w+$/].downcase 
          end

          def before_method(object)
            @callbacks.send('before_' + class_name(object), object)
          end

          def after_method(object)
            @callbacks.send('after_' + class_name(object), object)
          end

          def new_line
            @callbacks.new_line
          end
          
      end

      # Defines a set of callbacks which are triggered at various stages in the
      # Render class as the Data object is being unrolled. This class is meant
      # to be inherited from by classes that define costume behavior by
      # overriding methods to allow for the interpolation of arbitrary values 
      # into the diff Data object as it is being rendered.
      #
      # Though this seems like good functionality for a module, being able to
      # define a class that inherits from this makes the interface for
      # customization easier. Suggestions for improvements are much
      # appreciated.
      class Callbacks

        #:stopdoc:#
        def before_addblock(block)   '' end
        def before_remblock(block)   '' end
        def before_modblock(block)   '' end
        def before_unmodblock(block) '' end
        def before_sepblock(block)   '' end

        def after_addblock(block)    '' end
        def after_remblock(block)    '' end
        def after_modblock(block)    '' end
        def after_unmodblock(block)  '' end
        def after_sepblock(block)    '' end

        def before_addline(line)     '' end
        def before_remline(line)     '' end
        def before_modline(line)     '' end
        def before_unmodline(line)   '' end
        def before_sepline(line)     '' end

        def after_addline(line)      '' end
        def after_remline(line)      '' end
        def after_modline(line)      '' end
        def after_unmodline(line)    '' end
        def after_sepline(line)      '' end

        def new_line;              "\n" end
        #:startdoc:#
      end

      #:stopdoc:#
      class DebugCallbacks

        def method_missing(sym, *params)
          sym.id2name
        end

      end
      #:startdoc:#

      # Renders with HTML as the target output (only effect is escaped lines)
      # callbacks will still need to escape any lines they output
      class HTMLRenderer < Renderer #:nodoc:#
        
        # escapes
        def escape(text)
          #CGI::escapeHTML(text)
          text.gsub('&', '&amp;').
               gsub('<', '&lt;' ). 
               gsub('>', '&gt;' ).
               gsub('"', '&#34;')
        end
      end

    end
  end
end
