require 'routing_filter/base'

module RoutingFilter
  class ProjectsAndRepositories < Base
    
    # TODO: move somewhere else so project+repository validations can use it
    RESERVED_NAMES = ["teams"] + Dir[File.join(RAILS_ROOT, "public", "*")].map{|f| File.basename(f) }
    CONTROLLER_NAMES = ActionController::Routing.possible_controllers + RESERVED_NAMES
    
    NAME_WITH_FORMAT_RE = /[a-z0-9_\-\.]+/i
    
    def around_recognize(path, env, &block)
      if not_reserved?(path)
         if path =~ /^\/(#{NAME_WITH_FORMAT_RE})(\/.+)?/
           project_name = $1
           rest = $2
           if rest && not_reserved?(rest) && rest =~ /^\/(#{NAME_WITH_FORMAT_RE})(.+)?$/i
             path.replace "/projects/#{project_name}/repositories/#{$1}#{$2}"             
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
        # if params[:controller] == "projects" && %w[show edit update destroy].include?(params[:action])
        #   result.sub!(/^\/projects\/#{params[:id]}/, "/#{params[:id]}")
        # elsif params[:project_id]
        #   result.sub!(/^\/projects\/#{params[:project_id]}(.+)?/){ "/#{params[:project_id]}#{$1}"}
        # end
        if result =~ /^\/projects\/(#{NAME_WITH_FORMAT_RE})\/repositories\/(#{NAME_WITH_FORMAT_RE})(.+)?/
          result.replace "/#{$1}/#{$2}#{$3}"
        elsif result =~ /^\/projects\/(#{NAME_WITH_FORMAT_RE})(.+)?/
          result.replace "/#{$1}#{$2}"
        end
      end
    end
    
    def not_reserved?(path)
      CONTROLLER_NAMES.select{|s| path.starts_with?("/#{s}") }.length == 0
    end
  end
end