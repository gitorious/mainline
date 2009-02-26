require 'oauth/signature/hmac/base'
if RUBY_VERSION < '1.9'
   require 'hmac-sha2'
end
module OAuth::Signature::HMAC
  class SHA2 < Base
    implements 'hmac-sha2'
    digest_class RUBY_VERSION > '1.9' ? Digest::SHA2 : ::HMAC::SHA2
  end
end
