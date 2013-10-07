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

require 'test_helper'

class Service::JiraTest < ActiveSupport::TestCase
  def jira(attrs = {})
    Service::Jira.new({
      :username => "foo@bar.com",
      :password => "foobar",
      :url      => 'https://project.jira.test'
    }.merge(attrs))
  end

  should "validate presence of username" do
    assert jira(:username => "foo@bar.com").valid?
    refute jira(:username => "").valid?
  end

  should "validate presence of password" do
    assert jira(:password => 'foobar').valid?
    refute jira(:password => nil).valid?
  end

  context "#service_url" do
    should "return correct jira url" do
      assert_equal jira.service_url, "https://project.jira.test"
    end
  end

  context "#notify" do
    should "send payload to jira" do
      payload = { "foo" => "bar" }
      http = mock
      http.expects(:post).with(jira.service_url,
                               :body => payload.to_json,
                               :content_type => 'application/json',
                               :basic_auth => {:user => "foo@bar.com", :password => "foobar"})
      jira.notify(http, payload)
    end
  end
end
