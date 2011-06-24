# Extracted and adapted from devise_openid_authenticatable plugin
require 'devise/strategies/base'
require 'rack/openid'

module Devise
  module Strategies
    base_class = Authenticatable rescue Base
    class OpenidAuthenticatable < base_class

      def valid?
        identity_param?
      end

      def authenticate!
        # Delegate authentication to Rack::OpenID by throwing a 401
        opts = { :identifier => params[scope]["identity_url"], :return_to => return_url, :trust_root => trust_root, :method => 'post' }
        custom! [401, { Rack::OpenID::AUTHENTICATE_HEADER => Rack::OpenID.build_header(opts) }, "Sign in with OpenID"]
      end

      private

      def identity_param?
        params[scope].try(:[], 'identity_url')
      end

      def logger
        @logger ||= ((Rails && Rails.logger) || RAILS_DEFAULT_LOGGER)
      end

      def return_url
        request.url.sub(%r{//(.*?)/.*}, '//\1/complete-open-id-registration')
      end

      def trust_root
        trust_root = URI.parse(request.url)
        trust_root.path = ""
        trust_root.query = nil
        trust_root.to_s
      end
    end
  end
end

Warden::Strategies.add :openid_authenticatable, Devise::Strategies::OpenidAuthenticatable
