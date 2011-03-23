ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

require "shoulda"
require "mocha"
begin
  require "redgreen"
rescue LoadError
end

class ActiveSupport::TestCase
  include AuthenticatedTestHelper
  
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  NULL_SHA = "0" * 40 unless defined?(NULL_SHA)
  SHA = "a" * 40 unless defined?(SHA)
  OTHER_SHA = "f" * 40 unless defined?(OTHER_SHA)

  # Add more helper methods to be used by all tests here...
  
  def find_message_with_queue_and_regexp(queue_name, regexp)
    ActiveMessaging::Gateway.connection.clear_messages
    yield
    msg = ActiveMessaging::Gateway.connection.find_message(queue_name, regexp)
    assert_not_nil msg, "Message #{regexp.source} in #{queue_name} was not found"
    return ActiveSupport::JSON.decode(msg.body)
  end
  
  def repo_path
    File.join(File.dirname(__FILE__), "..", ".git")
  end
  
  def grit_test_repo(name)
    File.join(RAILS_ROOT, "vendor/grit/test", name )
  end
  
  def assert_incremented_by(obj, meth, value)
    value_before = obj.send(meth)
    yield
    value_after = obj.send(meth)
    error_msg = (value_before == value_after) ? "unchanged" : "incremented by #{(value_after - value_before)}"
    assert_equal(value, (value_after - value_before), "#{obj}##{meth} should be incremented by #{value} but was #{error_msg}")
  end

  def assert_includes(collection, object, message=nil)
    assert(collection.include?(object),
      (message || inclusion_failure(collection, object, true)))
  end

  def assert_not_includes(collection, object, message=nil)
    assert(!collection.include?(object),
      (message || inclusion_failure(collection, object, false)))
  end

  def inclusion_failure(collection, object, should_be_included)
    not_message = should_be_included ? "" : " not"
    "Expected collection (#{collection.count} items) #{not_message} to include #{object.class.name}"
  end

  def self.enforce_ssl
    context "when enforcing ssl" do
      setup do
        @use_ssl = GitoriousConfig["use_ssl"]
        GitoriousConfig["use_ssl"] = true
        login_as(:johan)
      end

      teardown do
        GitoriousConfig["use_ssl"] = @use_ssl
      end

      context "" do
        yield
      end
    end
  end

  def self.disable_ssl
    context "when not enforcing ssl" do
      setup do
        @use_ssl = GitoriousConfig["use_ssl"]
        GitoriousConfig["use_ssl"] = false
      end

      teardown do
        GitoriousConfig["use_ssl"] = @use_ssl
      end

      context "" do
        yield
      end
    end
  end

  def self.should_enforce_ssl_for(method, action, params = {}, &block)
    enforce_ssl do
      without_ssl_context do
        context "#{method.to_s.upcase} :#{action}" do
          setup do
            block.call unless block.nil?
            self.send(method, action, params)
          end

          should_redirect_to_ssl
        end
      end
    end

    disable_ssl do
      without_ssl_context do
        context "#{method.to_s.upcase} :#{action}" do
          should "not redirect to HTTPS" do
            begin
              self.send(method, action, params)
            rescue NoMethodError
              # Doesn't matter, this just means we hit the controller missing
              # some parameters
            end

            assert_not_equal "https://" + @request.host + @request.request_uri, @response.location
          end
        end
      end
    end
  end

  def self.should_render_in_global_context(options = {})
    should "Render in global context for actions" do
      filter = @controller.class.filter_chain.find(:require_global_site_context)
      assert_not_nil filter, ":require_global_site_context before_filter not set"
      unless options[:except].blank?
        assert_not_nil filter.options[:except], "no :except specified in controller"
        assert_equal [*options[:except]].flatten.map(&:to_s).sort, filter.options[:except].sort
      end
      unless options[:only].blank?
        assert_not_nil filter.options[:only], "no :only specified in controller"
        assert_equal [*options[:only]].flatten.map(&:to_s).sort, filter.options[:only].sort
      end
    end
  end
  
  def self.should_render_in_site_specific_context(options = {})
    should "Render in site specific context for actions" do
      filter = @controller.class.filter_chain.find(:redirect_to_current_site_subdomain)
      assert_not_nil filter, ":redirect_to_current_site_subdomain before_filter not set"
      unless options[:except].blank?
        assert_not_nil filter.options[:except], "no :except specified in controller"
        assert_equal [*options[:except]].flatten.map(&:to_s).sort, filter.options[:except].sort
      end
      unless options[:only].blank?
        assert_not_nil filter.options[:only], "no :only specified in controller"
        assert_equal [*options[:only]].flatten.map(&:to_s).sort, filter.options[:only].sort
      end
    end
  end

  def self.should_subscribe_to(queue_name)
    should "Subscribe to message queue #{queue_name}" do
      klass = self.class.name.sub(/Test$/, "").constantize

      subscription = ActiveMessaging::Gateway.subscriptions.values.find do |s|
        s.destination.name == queue_name && s.processor_class == klass
      end

      assert_not_nil subscription, "#{klass.name} does not subscribe to #{queue_name}"
    end
  end
end
