module OAuth
  class TestConsumer
    def initialize(options={})
    
    end
    
    def get_request_token
      TestRequestToken.new
    end

    def build_access_token(token, secret)
      if token == @valid_oauth_key and secret == @valid_oauth_secret      
        TestAccessToken.new(self, true)
      else
        TestAccessToken.new(self, false)
      end
    end
    
    # For testing: this is the key and secret required in order to obtain a valid access token
    def valid_outh_credentials=(options)
      @valid_oauth_key = options[:key]
      @valid_oauth_secret = options[:secret]
    end
    
  end
  
  class TestAccessToken
    def initialize(consumer, valid)
      @consumer = consumer
      @valid = valid
    end
    
    def valid?
      @valid 
    end
    
    def get(path)
      if valid?
        Net::HTTPSuccess.new(nil, nil, nil)
      else
        Net::HTTPFound.new(nil, nil, nil)
      end
    end
    
  end
  
  class TestRequestToken
    def initialize
      
    end
    
    def token
      
    end
    
    def secret
      
    end
    def authorize_url
      "http://no.host/authorize"
    end
  end
end