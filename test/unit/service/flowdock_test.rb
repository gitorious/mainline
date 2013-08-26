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

class Service::FlowdockTest < ActiveSupport::TestCase
  def flowdock(attrs = {})
    Service::Flowdock.new({ :flow_token => 'foobarbaz' }.merge(attrs))
  end

  should "validate presence of flow_token" do
    assert flowdock(:flow_token => "foo").valid?
    refute flowdock(:flow_token => "").valid?
  end

  context "#notify" do
    should "send payload to flowdock" do
      payload = { "foo" => "bar" }
      http = mock
      http.expects(:post).with(
        "#{Service::Flowdock::URL}/foobarbaz",
        :body => payload.to_json,
        :content_type => 'application/json'
      )
      flowdock.notify(http, payload)
    end
  end
end
