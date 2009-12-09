require File.dirname(__FILE__) + '/../test_helper'

class FeedItemTest < ActiveSupport::TestCase
  should_belong_to :event
  should_belong_to :watcher
end
