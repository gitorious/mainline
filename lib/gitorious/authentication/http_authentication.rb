module Gitorious
  module Authentication
    class HTTPAuthentication
      include UsernameTransformation
      include AutoRegistration

      def initialize(options)
        @login_variable = options['login_variable'] || 'REMOTE_USER'
        @variable_mapping = options['variable_mapping'] || {}
        super
      end

      def get_login(credentials)
        credentials.env && credentials.env[@login_variable]
      end

      def get_attributes(credentials)
	    Hash[@variable_mapping.map{|var_name, our_name| [our_name, (credentials.env || {})[var_name]]}]
      end
    end
  end
end
