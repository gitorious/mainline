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
require "gitorious/url"

class UrlTest < MiniTest::Spec
  it "does not use ssl by default" do
    url = Gitorious::Url.new("gitorious.here")

    refute url.ssl?
  end

  it "uses ssl" do
    url = Gitorious::Url.new("gitorious.here", 443, "https")

    assert url.ssl?
  end

  it "generates url" do
    url = Gitorious::Url.new("gitorious.here")

    assert_equal "http://gitorious.here/somewhere", url.url("/somewhere")
  end

  it "generates url for non-80 port" do
    url = Gitorious::Url.new("gitorious.here", 81)

    assert_equal "http://gitorious.here:81/somewhere", url.url("/somewhere")
  end

  it "generates url for ssl on port 443" do
    url = Gitorious::Url.new("gitorious.here", 443, "https")

    assert_equal "https://gitorious.here/somewhere", url.url("/somewhere")
  end
end
