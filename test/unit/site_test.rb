require File.dirname(__FILE__) + '/../test_helper'

class SiteTest < ActiveSupport::TestCase
  
  should_have_many :projects
  should_validate_presence_of :title
  
  
  should "have a default site with a nil subdomain" do
    default_site = Site.default
    assert_equal "Gitorious", default_site.title
    assert_nil default_site.subdomain
  end
  
  should 'not allow sites with http as subdomain' do
    site = Site.new
    site.subdomain = Site::HTTP_CLONING_SUBDOMAIN
    assert !site.save
    assert_not_nil site.errors.on(:subdomain)
  end
end
