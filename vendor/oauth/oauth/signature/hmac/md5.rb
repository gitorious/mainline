require 'oauth/signature/hmac/base'
if RUBY_VERSION < '1.9'
  require 'hmac-md5' 
end
module OAuth::Signature::HMAC
  class MD5 < Base
    implements 'hmac-md5'
    digest_class RUBY_VERSION > '1.9' ? Digest::MD5 : ::HMAC::MD5
  end
end
