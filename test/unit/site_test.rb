# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
