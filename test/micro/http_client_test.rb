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

require 'fast_test_helper'
require 'http_client'
require 'webmock/minitest'

class HttpClientTest < MiniTest::Spec
  class FakeLogger
    def self.info(*)
    end
  end

  let(:client) { HttpClient.new(FakeLogger) }

  it "posts form data using ssl" do
    stub_request(:post, "https://foo.bar").with(
      :body => { :payload => "str" },
      :header => {'Content-Type' => 'application/x-www-form-urlencoded'}
    )

    client.post("https://foo.bar/", :form_data => {:payload => "str"})
  end

  it "posts form data without ssl" do
    stub_request(:post, "http://foo.bar").with(
      :body => { :payload => "str" },
      :header => {'Content-Type' => 'application/x-www-form-urlencoded'}
    )

    client.post("http://foo.bar/", :form_data => {:payload => "str"})
  end

  it "posts using basic auth" do
    stub_request(:post, "https://usr:pwd@foo.bar").with(
      :body => "str",
      :header => {'Content-Type' => 'application/json'}
    )

    client.post("https://foo.bar/",
               :body => "str",
               :content_type => "application/json",
               :basic_auth => { :user => "usr", :password => "pwd"})
  end
end
