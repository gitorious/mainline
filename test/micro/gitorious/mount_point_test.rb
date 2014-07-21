# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "gitorious/mount_point"

class MountPointTest < MiniTest::Spec
  describe Gitorious::HttpMountPoint do
    it "does not use ssl by default" do
      mp = Gitorious::HttpMountPoint.new("gitorious.here")

      refute mp.ssl?
    end

    it "uses ssl" do
      mp = Gitorious::HttpMountPoint.new("gitorious.here", 443, "https")

      assert mp.ssl?
    end

    it "defaults to http on port 80" do
      mp = Gitorious::HttpMountPoint.new("gitorious.here")

      assert_equal "http://gitorious.here/somewhere", mp.url("/somewhere")
    end

    it "generates url for non-80 port" do
      mp = Gitorious::HttpMountPoint.new("gitorious.here", 81)

      assert_equal "http://gitorious.here:81/somewhere", mp.url("/somewhere")
    end

    it "generates url for ssl on port 443" do
      mp = Gitorious::HttpMountPoint.new("gitorious.here", 443, "https")

      assert_equal "https://gitorious.here/somewhere", mp.url("/somewhere")
    end

    it "generates url for ssl on port 443 when no port specified" do
      mp = Gitorious::HttpMountPoint.new("gitorious.here", nil, "https")

      assert_equal "https://gitorious.here/somewhere", mp.url("/somewhere")
    end

    it "generates url for ssl on non-443 port" do
      mp = Gitorious::HttpMountPoint.new("gitorious.here", 1918, "https")

      assert_equal "https://gitorious.here:1918/somewhere", mp.url("/somewhere")
    end

    it "considers gitorious.org a valid fqdn" do
      mp = Gitorious::HttpMountPoint.new("gitorious.org")

      assert mp.valid_fqdn?
    end

    it "considers host names without dots invalid fqdns" do
      mp = Gitorious::HttpMountPoint.new("localhost")

      refute mp.valid_fqdn?
    end

    describe "#can_share_cookies?" do
      it "can share on same host" do
        mp = Gitorious::HttpMountPoint.new("gitorious.org")
        assert mp.can_share_cookies?("gitorious.org")
      end

      it "can share with subdomains" do
        mp = Gitorious::HttpMountPoint.new("gitorious.org")
        assert mp.can_share_cookies?("qt.gitorious.org")
      end

      it "cannot share with different domain" do
        mp = Gitorious::HttpMountPoint.new("gitorious.org")
        refute mp.can_share_cookies?("gitorious.com")
      end

      it "cannot share cookies if not a fully qualified domain name" do
        mp = Gitorious::HttpMountPoint.new("gitorious")
        refute mp.can_share_cookies?("gitorious")
      end

      it "can share with same subdomain" do
        mp = Gitorious::HttpMountPoint.new("git.gitorious.org")
        assert mp.can_share_cookies?("git.gitorious.org")
        assert mp.can_share_cookies?("other.git.gitorious.org")
      end
    end
  end

  describe Gitorious::GitMountPoint do
    it "generates git urls" do
      mp = Gitorious::GitMountPoint.new("gitorious.org")
      url = mp.url("/gitorious/mainline.git")

      assert_equal "git://gitorious.org/gitorious/mainline.git", url
    end

    it "generates git urls for non-default port" do
      mp = Gitorious::GitMountPoint.new("gitorious.org", 9417)
      url = mp.url("/gitorious/mainline.git")

      assert_equal "git://gitorious.org:9417/gitorious/mainline.git", url
    end
  end

  describe Gitorious::GitSshMountPoint do
    it "generates ssh urls" do
      mp = Gitorious::GitSshMountPoint.new("git", "gitorious.org")
      url = mp.url("/gitorious/mainline.git")

      assert_equal "git@gitorious.org:gitorious/mainline.git", url
    end

    it "generates ssh url for url without leading slash" do
      mp = Gitorious::GitSshMountPoint.new("git", "gitorious.org")
      url = mp.url("gitorious/mainline.git")

      assert_equal "git@gitorious.org:gitorious/mainline.git", url
    end

    it "generates ssh url for non-standard port" do
      mp = Gitorious::GitSshMountPoint.new("git", "gitorious.org", 443)
      url = mp.url("/gitorious/mainline.git")

      assert_equal "ssh://git@gitorious.org:443/gitorious/mainline.git", url
    end
  end
end
