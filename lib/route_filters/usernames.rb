require 'routing_filter/base'

module RoutingFilter
  class Usernames < Base
        
    def around_recognize(path, env, &block)
      username = nil
      path.sub!(%r[^/~(#{User::USERNAME_FORMAT})]){ username = $1; '' }
      returning yield(path, env) do |params|
        if username
          params[:id] = username
          params[:controller] = "users"
          params[:action] = "show"
          params
        end
      end
    end
    
    def around_generate(*args, &block)
      params = args.extract_options!
      user = params[:id]
      returning yield do |result|
        return result unless result =~ /^\/users\/.+/
        if params[:controller] == "users" && params[:action] == "show" && user
          result = result.is_a?(Array) ? result.first : result
          result.replace "/~#{user.is_a?(User) ? user.to_param : user}"
        end
      end
    end
  end
end