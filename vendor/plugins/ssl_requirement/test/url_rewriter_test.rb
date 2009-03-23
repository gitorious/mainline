$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'action_controller'
require 'action_controller/test_process'

require "ssl_requirement"

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true
ActionController::Base.logger = nil
ActionController::Routing::Routes.reload rescue nil

class UrlRewriterTest < Test::Unit::TestCase
  def setup
    @request = ActionController::TestRequest.new
    @params = {}
    @rewriter = ActionController::UrlRewriter.new(@request, @params)
    
    puts @url_rewriter.to_s
  end

  def test_rewrite_secure_false
    SslRequirement.disable_ssl_check = false
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => false)
    )
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => false, :only_path => true)
    )
    
    SslRequirement.disable_ssl_check = true
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => false)
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => false, :only_path => true)
    )
  end
  
  def test_rewrite_secure_true
    SslRequirement.disable_ssl_check = false
    assert_equal('https://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => true)
    )
    assert_equal('https://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => true, :only_path => true)
    )
    
    SslRequirement.disable_ssl_check = true
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => true)
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => true, :only_path => true)
    )
  end
  
  def test_rewrite_secure_not_specified
    SslRequirement.disable_ssl_check = false
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a')
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :only_path => true)
    )
    
    SslRequirement.disable_ssl_check = true
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a')
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :only_path => true)
    )
  end
end