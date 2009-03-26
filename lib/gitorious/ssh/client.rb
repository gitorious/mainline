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

module Gitorious
  module SSH  
    class AccessDeniedError < StandardError; end
  
    class Client
      def initialize(strainer, username)
        @strainer = strainer
        @project_name, @repository_name = strainer.path.split("/", 2)
        @repository_name.gsub!(/\.git$/, "")
        @user_name = username
      end
      attr_accessor :project_name, :repository_name, :user_name
    
      def writable_by_user?
        query_for_permission_and_path
        @writable == "true"
      end
    
      def assure_user_can_write!
        writable_by_user? || raise(AccessDeniedError)
      end
    
      def query_url
        url = ["/#{@project_name}"]
        url << @repository_name
        url << "writable_by?username=#{@user_name}"
        url.join("/")
      end
      
      def real_path
        query_for_permission_and_path
        full_real_path = File.join(GitoriousConfig["repository_base_path"], @real_path)
        if !@real_path || @real_path == "nil" || !File.exist?(full_real_path)
          raise AccessDeniedError
        end
        full_real_path
      end
    
      def to_git_shell_argument
        "#{@strainer.verb} '#{real_path}'"
      end
      
      def query_for_permission_and_path
        if !@writable || !@real_path
          $stderr.puts "Querying #{query_url}" if $DEBUG
          resp = connection.get(query_url)
          @writable, @real_path = resp.body.split(" ")
        end
      end
    
      protected
        def connection
          port = GitoriousConfig["gitorious_client_port"]
          host = GitoriousConfig["gitorious_client_host"]
          @connection ||= Net::HTTP.start(host, port)
        end
    end
  end
end