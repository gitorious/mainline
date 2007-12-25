require File.dirname(__FILE__) + "/test_helper"

class ResourcePathsTest < Test::Unit::TestCase
  
  def setup
    ActionController::Routing::Routes.draw do |map|
      map.resources :blogs, :path_name => "blawghs" do |b|
        b.resources :posts, :path_name => "thingies"
      end
      map.resources :posts
      map.resources :blogs do |b|
        b.resources :posts, :path_name => "blabbers"
      end
    end
  end
  
  def test_sanity
    expected_options = { :controller => "posts", :action => "index" }
    assert_recognizes(expected_options, :path => 'posts/', :method => :get)
  end
  
  def test_it_should_recognize_a_custom_path_name
    expected_options = { :controller => "blogs", :action => "index" }
    assert_recognizes(expected_options, :path => 'blawghs/', :method => :get)
  end
  
  def test_it_works_with_nested_resources_too
    expected_options = { :controller => "posts", :action => "index", :blog_id => "42" }
    assert_recognizes(expected_options, :path => 'blogs/42/blabbers/', :method => :get)
  end
  
  def test_it_works_with_nested_resources_that_both_have_custom_path_names
    expected_options = { :controller => "posts", :action => "index", :blog_id => "42" }
    assert_recognizes(expected_options, :path => 'blawghs/42/thingies/', :method => :get)
  end
  
end
