require 'oauth/signature/hmac/base'
require 'rubygems'
if RUBY_VERSION < '1.9'
  require 'hmac-sha1' 
end

module OAuth::Signature::HMAC
  class SHA1 < Base
    implements 'hmac-sha1'
    digest_class RUBY_VERSION > '1.9' ? Digest::SHA1 : ::HMAC::SHA1
  end
end
