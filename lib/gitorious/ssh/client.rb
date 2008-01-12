require "net/http"

module Gitorious
  module SSH  
    class AccessDeniedError < StandardError; end
  
    class Client
      def initialize(strainer, username)
        @strainer = strainer
        @project_name, @repository_name = strainer.path.split("/")
        @repository_name.gsub!(/\.git$/, "")
        @user_name = username
      end
      attr_accessor :project_name, :repository_name, :user_name
    
      def writable_by_user?
        $stderr.puts "Querying #{query_url}" if $DEBUG
        resp = connection.get(query_url)
        resp.body == "true"
      end
    
      def assure_user_can_write!
        writable_by_user? || raise(AccessDeniedError)
      end
    
      def query_url
        url = ["/projects"]
        url << @project_name
        url << "repos"
        url << @repository_name
        url << "writable_by?username=#{@user_name}"
        url.join("/")
      end
    
      def to_git_shell_argument
        "#{@strainer.verb} '#{@strainer.full_path}'"
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