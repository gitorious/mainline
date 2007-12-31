module Gitorious
  module SSH
    class BadCommandError < StandardError
    end
  
    class Strainer
    
      COMMANDS_READONLY = [ 'git-upload-pack' ]
      COMMANDS_WRITE    = [ 'git-receive-pack' ]
      ALLOW_RE = /^'([a-z0-9][a-z0-9@._\-]*(\/[a-z0-9][a-z0-9@\._\-]*)*\.git)'$/i.freeze
    
      def initialize(command)
        @command = command
        @verb = nil
        @argument = nil
        @path = nil
      end
      attr_reader :path, :verb, :command
    
      def full_path
        File.join(File.expand_path("~"), "repositories", path)
      end
    
      def parse!
        if @command.include?("\n")
          raise BadCommandError
        end
      
        @verb, @argument = @command.split(" ")
        if @argument.nil? || @argument.is_a?(Array)
          # all known commands take one argument; improve if/when needed
          raise BadCommandError
        end
      
        if !(COMMANDS_WRITE.include?(@verb)) && !(COMMANDS_READONLY.include?(@verb))
          raise BadCommandError
        end
      
        if ALLOW_RE =~ @argument
          @path = $1
          raise BadCommandError unless @path
        else
          raise BadCommandError
        end
      
        self
      end
    end
  end
end
