# Pass an instance of this class to a Gitorious::Authentication plugin's
# authenticate method.
module Gitorious
  module Authentication
    class Credentials
      attr_accessor :username, :password, :env
      # "username" is the client-supplied username value.
      # "password" is the client-supplied password value.
      # "env" is the HTTP environment from the web server.
      # If you use "env", you may want to examine env['REMOTE_USER'],
      # etc.
    end
  end
end
