require 'oauth/signature/base'

module OAuth::Signature::HMAC
  class Base < OAuth::Signature::Base

  private

    def digest
      if RUBY_VERSION > '1.9'
        Digest::HMAC.new(secret, self.class.digest_class).digest(signature_base_string)
      else
        self.class.digest_class.digest(secret, signature_base_string)
      end
    end
  end
end
