require 'oauth/signature/base'

module OAuth::Signature
  class PLAINTEXT < Base
    implements 'plaintext'

    def signature
      signature_base_string
    end

    def ==(cmp_signature)
      if cmp_signature.is_a?(Array)   # Ruby 1.9
        return signature == escape(cmp_signature.first)
      else
        return signature == escape(cmp_signature)
      end
    end

    def signature_base_string
      secret
    end

    def secret
      escape(super)
    end
  end
end
