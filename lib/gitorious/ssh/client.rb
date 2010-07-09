# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

require "net/http"
require 'uri'

module Gitorious
  module SSH  
    class AccessDeniedError < StandardError; end
  
    class Client
      def initialize(strainer, username)
        @strainer = strainer
        @project_name, @repository_name = strainer.path.split("/", 2)
        @repository_name.gsub!(/\.git$/, "")
        @user_name = username
        @configuration = {}
      end
      attr_accessor :project_name, :repository_name, :user_name
    
      def writable_by_user?
        query_for_permission_and_path
        @writable == "true"
      end
    
      def assure_user_can_write!
        writable_by_user? || raise(AccessDeniedError)
      end
    
      # The full URL
      def writable_by_query_url
        writable_by_query_uri.to_s
      end

      # The path only
      def writable_by_query_path
        writable_by_query_uri.request_uri
      end
      
      def real_path
        if !configuration["real_path"] || configuration["real_path"] == "nil"
          raise AccessDeniedError
        end
        full_real_path = File.join(GitoriousConfig["repository_base_path"],
          configuration["real_path"])
        raise AccessDeniedError unless File.exist?(full_real_path)
        full_real_path
      end

      def force_pushing_denied?
        configuration["force_pushing_denied"] == "true"
      end
    
      def to_git_shell_argument
        "#{@strainer.verb} '#{real_path}'"
      end
      
      def pre_receive_hook_exists?
        filename = File.join(real_path, "hooks", "pre-receive")
        File.executable?(filename)
      end
      
      def configuration
        if @configuration.empty?
          query_url = "/#{@project_name}/#{@repository_name}/config"
          # $stderr.puts "Querying #{query_url}" if $DEBUG
          resp = connection.get(query_url)
          # $stderr.puts resp
          parse_configuration(resp.body)
        end
        @configuration
      end
    
      protected
        def parse_configuration(raw_config)
          raw_config.split("\n").each do |line|
            key, val = line.split(":")
            if key && val
              @configuration[key] = val
            end
          end
        end
      
        def connection
          port = GitoriousConfig["gitorious_client_port"]
          host = GitoriousConfig["gitorious_client_host"]
          @connection ||= Net::HTTP.start(host, port)
        end
        
        # Returns an actual URI object
        def writable_by_query_uri
          path = "/#{@project_name}/#{@repository_name}/writable_by"
          query = "username=#{@user_name}"
          host = GitoriousConfig['gitorious_client_host']
          _port = GitoriousConfig['gitorious_client_port']
          port = RUBY_VERSION > '1.9' ? _port : _port.to_s  # Ruby 1.9 expects a number, while 1.8 expects a string. Oh well
          URI::HTTP.build(:host => host, :port => port, :path => path, :query => query)
        end
        
    end
  end
end
