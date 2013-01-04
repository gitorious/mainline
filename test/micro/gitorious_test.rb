# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
require "minitest/autorun"
require "config/initializers/gitorious_config"
require "gitorious"

class GitoriousTest < MiniTest::Spec
  after do
    ENV.delete("GITORIOUS_HOST")
  end

  it "uses GITORIOUS_ environment variables" do
    ENV["GITORIOUS_HOST"] = "gitorious.org"
    assert_equal "gitorious.org", Gitorious.host
  end

  describe "support email" do
    it "defaults to gitorious-support@<host>" do
      Gitorious::Configuration.override("host" => "my.gitorio.us") do |conf|
        assert_equal "gitorious-support@my.gitorio.us", Gitorious.support_email
      end
    end

    it "uses configured sender" do
      Gitorious::Configuration.override("support_email" => "cj@gitorious.org") do |conf|
        assert_equal "cj@gitorious.org", Gitorious.support_email
      end
    end
  end

  describe "email sender" do
    it "defaults to Gitorious <no-reply@<host>>" do
      Gitorious::Configuration.override("host" => "my.gitorio.us") do |conf|
        assert_equal "Gitorious <no-reply@my.gitorio.us>", Gitorious.email_sender
      end
    end

    it "uses configured sender" do
      Gitorious::Configuration.override("email_sender" => "cj@gitorious.org") do |conf|
        assert_equal "cj@gitorious.org", Gitorious.email_sender
      end
    end
  end

  describe "ops?" do
    it "returns true for known IP" do
      Gitorious::Configuration.override("remote_ops_ips" => "192.168.122.1") do
        assert Gitorious.ops?("192.168.122.1")
      end
    end

    it "returns true for one of several known IPs" do
      ips = ["192.168.122.1", "127.0.0.1", "10.0.0.19"]

      Gitorious::Configuration.override("remote_ops_ips" => ips) do
        assert Gitorious.ops?("10.0.0.19")
      end
    end

    it "returns false for unknown IP" do
      ips = ["192.168.122.1", "127.0.0.1", "10.0.0.19"]

      Gitorious::Configuration.override("remote_ops_ips" => ips) do
        refute Gitorious.ops?("10.0.0.1")
      end
    end

    it "recognizes localhost by default" do
      Gitorious::Configuration.override({}) do
        assert Gitorious.ops?("127.0.0.1")
      end
    end

    it "does not recognize localhost when not in specified ips" do
      Gitorious::Configuration.override("remote_ops_ips" => "192.168.122.1") do
        refute Gitorious.ops?("127.0.0.1")
      end
    end
  end
end
