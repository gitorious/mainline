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
require "fast_test_helper"
require "config/gitorious_config"
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

  describe "max tarball size" do
    it "defaults to 0" do
      assert_equal 0, Gitorious.max_tarball_size
    end

    it "uses configured value" do
      Gitorious::Configuration.override("max_tarball_size" => "156") do
        assert_equal 156, Gitorious.max_tarball_size
      end
    end

    it "groks kilobytes" do
      Gitorious::Configuration.override("max_tarball_size" => "1K") do
        assert_equal 1024, Gitorious.max_tarball_size
      end
    end

    it "groks megabytes" do
      Gitorious::Configuration.override("max_tarball_size" => "1M") do
        assert_equal 1048576, Gitorious.max_tarball_size
      end
    end

    it "groks gigabytes" do
      Gitorious::Configuration.override("max_tarball_size" => "1G") do
        assert_equal 1073741824, Gitorious.max_tarball_size
      end
    end

    it "is tarballable if there's no limit" do
      repo = Repository.new(:disk_usage => 1024)
      assert Gitorious.tarballable?(repo)
    end

    it "is tarballable if there's no disk usage data" do
      Gitorious::Configuration.override("max_tarball_size" => "1K") do
        repo = Repository.new
        assert Gitorious.tarballable?(repo)
      end
    end

    it "is tarballable if repo size is within limits" do
      Gitorious::Configuration.override("max_tarball_size" => "1K") do
        repo = Repository.new(:disk_usage => 1022)
        assert Gitorious.tarballable?(repo)
      end
    end

    it "is tarballable if repo size is exactly on the limit" do
      Gitorious::Configuration.override("max_tarball_size" => "1K") do
        repo = Repository.new(:disk_usage => 1024)
        assert Gitorious.tarballable?(repo)
      end
    end

    it "is not tarballable if repo size exceeds limits" do
      Gitorious::Configuration.override("max_tarball_size" => "1K") do
        repo = Repository.new(:disk_usage => 2042)
        refute Gitorious.tarballable?(repo)
      end
    end
  end
end
