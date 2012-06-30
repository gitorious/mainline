module Gitorious
  module Authentication
    class SSLAuthentication
      attr_reader(:login_field, :login_replace_char, :login_strip_domain)

      def initialize(options)
        @login_field = options['login_field'] || 'CN'
        @login_replace_char = options['login_replace_char'] || '-'
        @login_strip_domain = options['login_strip_domain']
      end

      def authenticate(credentials)
        return false unless credentials.env
        username = username_from_ssl_header(credentials.env)
        User.find_by_login(username) || auto_register(username, credentials.env)
      end

      def username_from_ssl_header(env)
        username = env['SSL_CLIENT_S_DN_' + login_field]
        username = username.split('@')[0] if login_strip_domain
        username.gsub(/[^a-z0-9\-]/i, login_replace_char)
      end

      def auto_register(username, env)
        user = User.new

        user.login = username
        user.email = env['SSL_CLIENT_S_DN_Email']
        user.fullname = env['SSL_CLIENT_S_DN_CN']
        user.password = 'left_blank'
        user.password_confirmation = 'left_blank'
        user.terms_of_use = '1'
        user.aasm_state = 'terms_accepted'
        user.activated_at = Time.now.utc
        user.save!

        # Reset the password to something random
        user.reset_password!
        user
      end
    end
  end
end
