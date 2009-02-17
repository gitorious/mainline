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
    assert_equal(value, (value_after - value_before), "#{obj}##{meth} should be incremented by #{value} but was incremented by #{(value_after - value_before)}")
  end
end
