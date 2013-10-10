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
      :username    => "foo@bar.com",
      :password    => "foobar",
      :api_version => "4.3",
      :url         => "https://project.jira.test"
    }.merge(attrs))
  end

  should "validate presence of username" do
    assert jira(:username => "foo@bar.com").valid?
    refute jira(:username => "").valid?
  end

  should "validate presence of password" do
    assert jira(:password => "foobar").valid?
    refute jira(:password => nil).valid?
  end

  context "#service_url" do
    should "return correct jira url" do
      assert_equal(
        jira.service_url(123),
        "https://project.jira.test/rest/api/4.3/issue/123/transitions"
      )
    end
  end

  context "#notify" do
    %w(transition status).each do |keyword|
      setup do
        @payload = {
          "url"     => "http://some.commit",
          "message" => "hello world [#123 #{keyword}:yo resolution:oh-hai]"
        }

        @http = mock
      end

      should "send payload to jira when #{keyword} is provided" do
        body = {
          :fields => {
            :resolution => {
              :name => "oh-hai".inspect
            },
          },
          :update => {
            :comment => [{
              :add => {
                :body => "#{@payload['message']}\n#{@payload['url']}"
              }
            }]
          },
          :transition => { :name => "yo".inspect },
        }.to_json

        @http.expects(:post).with(
          jira.service_url(123),
          :body         => body,
          :content_type => "application/json",
          :basic_auth   => { :user => "foo@bar.com", :password => "foobar" }
        )

        jira.notify(@http, @payload)
      end

      should "do nothing if message doesn't include #{keyword} info" do
        payload = { "message" => "hello world [#123 foo:bar]" }
        http    = mock

        assert_nil jira.notify(http, payload)
      end
    end

    should "do nothing if message doesn't include issue id" do
      payload = { "message" => "hello world [123 transition:oh-hai]" }
      http    = mock

      assert_nil jira.notify(http, payload)
    end
  end
end
