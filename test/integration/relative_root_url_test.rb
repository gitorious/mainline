# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

$ROOT = ENV['RAILS_RELATIVE_URL_ROOT'] = '/git'

require "test_helper"

class RelativeRootUrlTest < ActionController::IntegrationTest

  def setup
    assert_not_nil Rails.application.config.relative_url_root, 'Rails relative URL root not configured'
    assert_equal $ROOT, Rails.application.config.relative_url_root, 'Rails relative URL root is not #{$ROOT}'
  end

  should "routing works with relative root" do
    assert_routing $ROOT, { :controller => 'site', :action => 'index' }
  end

  should "static files work with relative root" do
    get $ROOT
    assert_select 'link[rel="shortcut icon"]' do |favicons|
      assert_equal favicons.count, 1
      assert_equal favicons.first.attributes['href'], "#{$ROOT}/favicon.ico"
    end
    assert_select 'link[rel="stylesheet"]' do |stylesheets|
      stylesheets.each do |stylesheet|
        assert stylesheet.attributes['href'].index("#{$ROOT}/stylesheets") == 0,
            "Style sheet not under %s: %s" % ["#{$ROOT}/stylesheets", stylesheet.attributes['href']]
      end
    end
    assert_select 'script[src]' do |javascripts|
      javascripts.each do |javascript|
        assert javascript.attributes['src'].index("#{$ROOT}/javascripts") == 0,
            "JavaScript file not under %s: %s" % ["#{$ROOT}/javascripts", javascript.attributes['src']]
      end
    end
  end

  should "links work with relative root" do
    get $ROOT
    assert_select '*#menu a' do |links|
      links.each do |link|
        assert link.attributes['href'].index($ROOT) == 0,
            "Link not pointing under %s: %s" % [$ROOT, link.attributes['href']]
      end
    end
  end

  should "login and logout works with relative root" do
    post_via_redirect "#{$ROOT}/sessions", :email => users(:johan).email, :password => 'test'
    assert_response :success, "Login with relative URL root #{$ROOT} failed"
    assert_equal 'Logged in successfully', flash[:notice], "Not logged in successfully with relative URL root #{$ROOT}"
    assert_equal $ROOT, path, "Not redirected to relative URL root #{$ROOT} after login"
    get_via_redirect "#{$ROOT}/logout"
    assert_response :success, "Logout with relative URL root #{$ROOT} failed"
    assert_equal 'You have been logged out.', flash[:notice], "Not logged out successfully with relative URL root #{$ROOT}"
    assert_equal $ROOT, path, "Not redirected to relative URL root #{$ROOT} after logout"
  end
end
