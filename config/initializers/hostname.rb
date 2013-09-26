if !Gitorious.site.valid_fqdn? && defined?(Rails)
  Rails.logger.warn "Invalid subdomain name #{Gitorious.host}. Session cookies will not work!\n" +
    "See http://gitorious.org/gitorious/pages/ErrorMessages for further explanation"
end
