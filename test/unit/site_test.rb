require File.dirname(__FILE__) + '/../test_helper'

class SiteTest < ActiveSupport::TestCase
  
  should_have_many :projects
  should_validate_presence_of :title
  
  should "have a default site with a nil subdomain" do
    default_site = Site.default
    assert_equal "Gitorious", default_site.title
    assert_nil default_site.subdomain
  end
end
