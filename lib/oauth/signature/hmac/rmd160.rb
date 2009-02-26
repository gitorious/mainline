require 'oauth/signature/hmac/base'
if RUBY_VERSION < '1.9'
  require 'hmac-rmd160' 
end
module OAuth::Signature::HMAC
  class RMD160 < Base
    implements 'hmac-rmd160'
    digest_class RUBY_VERSION > '1.9' ? Digest::RMD160 : ::HMAC::RMD160
  end
end
