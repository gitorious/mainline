# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

# Middleware that handles HTTP cloning
# This piece of code is performed before the Rails stack kicks in.
# If we return a 404 status code, control is passed on to Rails
#
# What it does is:
# - Check if the hostname begins with +http+ (this will be reserved in
#   the site model)
# - As longs as we're sure we are in our own context, rip out the repo
#   path and rest from the URI
# - Return a X-Sendfile header in the response containing the full
#   path to the object requested
# - This will be picked up by Apache (given mod-x_sendfile is
#   installed) and then delivered to the client
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

class GitHttpCloner
  TRUSTED_PROXIES = /^127\.0\.0\.1$|^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\./i
  NOT_FOUND_RESPONSE = [404, {"Content-Type" => "text/html"},[]]

  def self.call(env)
    perform_http_cloning = env['HTTP_HOST'] =~ /^#{Site::HTTP_CLONING_SUBDOMAIN}\..*/
    if perform_http_cloning && !GitoriousConfig['hide_http_clone_urls']
      if env["PATH_INFO"] =~ /^\/robots.txt$/
        body = ["User-Agent: *\nDisallow: /\n"]
        return [200, {"Content-Type" => "text/plain"}, body]
      elsif match = /(.*\.git)(.*)/.match(env['PATH_INFO'])
        path = match[1]
        rest = match[2]
        begin
          repo = Repository.find_by_path(path)
          return NOT_FOUND_RESPONSE unless repo
          repo.cloned_from(remote_ip(env), nil, nil, 'http') if rest == '/HEAD'          
          full_path = File.join(repo.full_repository_path, rest)
          headers = {
            "X-Sendfile" => full_path,
            'Content-Type' => 'application/octet-stream'
          }
          env["rack.session.options"] = {}
          return [200, headers, []]
        rescue ActiveRecord::RecordNotFound   
          # Repo not found
          return NOT_FOUND_RESPONSE
        end
      end
    end
    return NOT_FOUND_RESPONSE
  end

  protected 
    # Borrowed from ActionController::Request. Extract proxy addresses and stuff (except our own)
    # Does not do ip spoofing checks
    def self.remote_ip(env)
      remote_addr_list = env['REMOTE_ADDR'] && env['REMOTE_ADDR'].scan(/[^,\s]+/)
      unless remote_addr_list.blank?
        not_trusted_addrs = remote_addr_list.reject {|addr| addr =~ TRUSTED_PROXIES}
        return not_trusted_addrs.first unless not_trusted_addrs.empty?
      end

      remote_ips = env['HTTP_X_FORWARDED_FOR'] && env['HTTP_X_FORWARDED_FOR'].split(',')

      if env.include? 'HTTP_CLIENT_IP'
        return env['HTTP_CLIENT_IP']
      end

      if remote_ips
        while remote_ips.size > 1 && TRUSTED_PROXIES =~ remote_ips.last.strip
          remote_ips.pop
        end
        return remote_ips.last.strip
      end

      env['REMOTE_ADDR']
    end
end
