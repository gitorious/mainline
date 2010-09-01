# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
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

# The Strainer class (and the associated script/gitorious) was inspired by
# the approach gitosis (http://eagain.net/gitweb/?p=gitosis.git) takes, 
# frankly the meat of it is a straight up port/fork of the core functionality, 
# including logic and general approach.
# Gitosis is of this writing licensed under the GPLv2 and is copyright (c) Tommi Virtanen
# and can be found at http://eagain.net/gitweb/?p=gitosis.git
# Gitorious::SSH::Strainer is licensed under the same license.

module Gitorious
  module SSH
    class BadCommandError < StandardError
    end
  
    class Strainer
    
      COMMANDS_READONLY = [ 'git-upload-pack', 'git upload-pack',
                            'git-upload-archive', 'git upload-archive' ]
      COMMANDS_WRITE    = [ 'git-receive-pack', 'git receive-pack' ]
      ALLOW_RE = /^'\/?([a-z0-9\+~][a-z0-9@._\-]*(\/[a-z0-9][a-z0-9@\._\-]*)*\.git)'$/i.freeze
    
      def initialize(command)
        @command = command
        @verb = nil
        @argument = nil
        @path = nil
      end
      attr_reader :path, :verb, :command
      
      def parse!
        if @command.include?("\n")
          raise BadCommandError
        end
        
        @verb, @argument = spliced_command
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
      
      protected
        def spliced_command
          args =  @command.split(" ")
          if args.length == 3
            ["#{args[0]} #{args[1]}", args[2]]
          elsif args.length == 2
            args
          else
            raise BadCommandError
          end
        end
    end
  end
end
