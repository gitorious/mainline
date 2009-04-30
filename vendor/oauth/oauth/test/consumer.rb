module OAuth
  class TestConsumer
    def initialize(options={})
    
    end
    
    def get_request_token(options={})
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
    def valid_oauth_credentials=(options)
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
    
    def request(path, options)
      if valid?
        result = Net::HTTPAccepted.new(nil, nil, nil)
        def result.body
          "Thank you for your contribution"
        end
        def result.[](key)
          {'X-Contribution-Agreement-Version' => 'valid_version_sha'}[key]
        end
        result
      else
        result = Net::HTTPFound.new(nil, nil, nil)
        def result.body
          ""
        end
        result
      end
    end
    
    def get(path, options={})
      request(path, options)
    end
    
    def post(path, options={})
      request(path, options)
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