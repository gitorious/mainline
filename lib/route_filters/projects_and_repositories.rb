require "gitorious/reservations"
require 'routing_filter/base'

module RoutingFilter
  class ProjectsAndRepositories < Base
    
    RESERVED_NAMES = Gitorious::Reservations::RESERVED_ROOT_NAMES
    CONTROLLER_NAMES = Gitorious::Reservations::CONTROLLER_NAMES + RESERVED_NAMES
    NAME_WITH_FORMAT_RE = /[a-z0-9_\-\.]+/i
    
    def around_recognize(path, env, &block)
      if !reserved?(path)
         if path =~ /^\/(#{NAME_WITH_FORMAT_RE})(\/.+)?/
           project_name = $1
           rest = $2
           if rest && !reserved?(rest) && repository_scope?(rest)
             path.replace "/projects/#{project_name}/repositories#{rest}"             
           else
             path.replace "/projects/#{project_name}#{rest}"
           end
         end
      end
      returning yield(path, env) do |params|
        params
      end
    end
    
    def around_generate(*args, &block)
      params = args.extract_options!
      returning yield do |result|
        result = result.is_a?(Array) ? result.first : result
        if result =~ /^\/projects\/(#{NAME_WITH_FORMAT_RE})\/repositories\/(#{NAME_WITH_FORMAT_RE})(.+)?/
          result.replace "/#{$1}/#{$2}#{$3}"
        elsif result =~ /^\/projects\/(#{NAME_WITH_FORMAT_RE})(.+)?/
          result.replace "/#{$1}#{$2}"
        end
      end
    end

    private
      def reserved?(path)
        CONTROLLER_NAMES.select{|s| path.starts_with?("/#{s}") }.length != 0
      end
      
      def repository_scope?(path)
        !Gitorious::Reservations::PROJECTS_MEMBER_ACTIONS.include?(path.sub("/", "")) && 
          path =~ /^\/(#{NAME_WITH_FORMAT_RE})(.+)?$/i
      end
  end
end