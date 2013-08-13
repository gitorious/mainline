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

class Service::SprintlyTest < ActiveSupport::TestCase
  def sprintly(attrs = {})
    Service::Sprintly.new({
      :email => "foo@bar.com",
      :product_id => 123,
      :api_key => "324asfd"
    }.merge(attrs))
  end

  should "validate presence of email" do
    assert sprintly(:email => "foo@bar.com").valid?
    refute sprintly(:email => "").valid?
  end

  should "validate presence of product_id" do
    assert sprintly(:product_id => 13).valid?
    refute sprintly(:product_id => nil).valid?
  end

  should "validate presence of api_key" do
    assert sprintly(:api_key => "3abc12").valid?
    refute sprintly(:api_key => "").valid?
  end

  context "#notify" do
    should "send payload to sprintly" do
      payload = { "foo" => "bar" }
      http = mock
      http.expects(:post).with("https://sprint.ly/integration/github/123/push/",
                               :body => payload.to_json,
                               :content_type => 'application/json',
                               :basic_auth => {:user => "foo@bar.com", :password => "324asfd"})
      sprintly.notify(http, payload)
    end
  end
end
