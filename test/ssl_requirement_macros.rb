# Copied from ssl_requirement gem
Test::Unit::TestCase.class_eval do
  def self.without_ssl_context
    context "without ssl" do
      setup do
        @request.env['HTTPS'] = nil
      end

      context "" do
        yield
      end
    end
  end

  def self.with_ssl_context
    context "with ssl" do
      setup do
        @request.env['HTTPS'] = 'on'
      end

      context "" do
        yield
      end
    end
  end

  def self.should_redirect_to_ssl
    should 'redirect to ssl' do
      assert_redirected_to "https://" + @request.host + @request.fullpath
    end
  end
end
