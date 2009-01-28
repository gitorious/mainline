require 'routing_filter/base'

module RoutingFilter
  class Teams < Base
    
    # FIXME: merge with usernames.rb, only the token (~/+) differs
    def around_recognize(path, env, &block)
      teamname = nil
      path.sub!(%r[^/\+(#{Group::NAME_FORMAT})]){ teamname = $1; "/teams/#{teamname}" }
      returning yield(path, env) do |params|
        if teamname && path.chomp("/") == "/teams/#{teamname}"
          params[:id] = teamname
          params[:controller] = "groups"
          params[:action] = "show"
          params
        elsif teamname
          params[:group_id] = teamname
        end
      end
    end
    
    def around_generate(*args, &block)
      params = args.extract_options!
      returning yield do |result|
        return result unless result =~ /^\/teams\/.+/
        if params[:controller] == "groups"
          team = params[:id]
        elsif params.blank? && (args.size == 1 && args.first.is_a?(Group))
          # we get here if people use named routes + positional obj (foo_path(@foo))
          team = args.first
          params[:group_id] = team
        else
          team = params[:group_id]
        end
        result = result.is_a?(Array) ? result.first : result
        team = team.is_a?(Group) ? team.to_param : team
        if params[:controller] == "groups" && params[:action] == "show" && team
          result.replace "/+#{team}"
        elsif params[:group_id] && team
          result.sub!(/^\/teams\/#{Group::NAME_FORMAT}/, "/+#{team}")
        end
      end
    end
  end
end
