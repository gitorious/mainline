require 'action_controller/url_rewriter'

module ActionController
  class UrlRewriter
    
    # Add a secure option to the rewrite method.
    def rewrite_with_secure_option(options = {})
      secure = options.delete(:secure)
      if !secure.nil? && !SslRequirement.disable_ssl_check?
        if secure == true || secure == 1 || secure.to_s.downcase == "true"
          options.merge!({
            :only_path => false,
            :protocol => 'https'
          })
        else
          options.merge!({
            :only_path => false,
            :protocol => 'http'
          })
        end
      end
      
      rewrite_without_secure_option(options)
    end
    alias_method_chain :rewrite, :secure_option
  end
end
