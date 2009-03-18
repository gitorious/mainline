# Middleware that handles HTTP cloning
# This piece of code is performed before the Rails stack kicks in. 
# If we return a 404 status code, control is passed on to Rails
#
# What it does is:
# - Check if the hostname begins with +http+ (this will be reserved in the site model)
# - As longs as we're sure we are in our own context, rip out the repo path and rest from the URI
# - Return a X-Sendfile header in the response containing the full path to the object requested
# - This will be picked up by Apache (given mod-x_sendfile is installed) and then delivered to the client
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

class GitHttpCloner
  def self.call(env)
    perform_http_cloning = env['HTTP_HOST'] =~ /^http.*/
    if perform_http_cloning
      if match = /(.*\.git)(.*)/.match(env['PATH_INFO'])
        path = match[1]
        rest = match[2]
        begin
          repo = Repository.find_by_path(path)
          full_path = File.join(GitoriousConfig['repository_base_path'], repo.real_gitdir, rest)
          return [200, {"X-Sendfile" => full_path}, []]
        rescue ActiveRecord::RecordNotFound   
          # Repo not found
        end
      end
    end
    return [404, {"Content-Type" => "text/html"},[]]
  end
end