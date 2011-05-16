# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
require File.dirname(__FILE__) + '/../../../../messaging_test_helper'
require "gitorious/messaging"

class TestPublisher
  include Gitorious::Messaging::Publisher
  include Gitorious::Messaging::TestAdapter::Publisher
end

class MessagingTestAdapterTest < ActiveSupport::TestCase
  context "publisher" do
    teardown do
      Gitorious::Messaging::TestAdapter.clear
    end

    should "return empty array if no messages were published" do
      assert_equal [], Gitorious::Messaging::TestAdapter.messages_on("/queue/MyQueue")
    end

    should "return array of parsed payloads when messages were published" do
      publisher = TestPublisher.new
      publisher.publish("/queue/MyQueue", { :id => 42 })
      publisher.publish("/queue/MyQueue", { :msg => "Ok" })

      assert_equal([{ "id" => 42 }, { "msg" => "Ok" }],
                   Gitorious::Messaging::TestAdapter.messages_on("/queue/MyQueue"))
    end

    should "pass assertion when matching message was published" do
      publisher = TestPublisher.new
      publisher.publish("/queue/MyQueue", { :id => 42 })

      assert_published "/queue/MyQueue", "id" => 42
    end

    should "fail assertion when matching message was not published" do
      publisher = TestPublisher.new
      publisher.publish("/queue/MyQueue", { :id => 42 })

      assert_raise RuntimeError do
        assert_published "/queue/MyQueue", "id" => 40
      end
    end
  end
end
