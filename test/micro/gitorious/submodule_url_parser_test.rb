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

require "fast_test_helper"
require 'gitorious'
require 'gitorious/submodule_url_parser'

module Gitorious
  class SubmoduleUrlParserTest < MiniTest::Spec
    let(:parser) { SubmoduleUrlParser.new }
    let(:expected_url) { "http://gitorious.test/foo/bar/source/sha123" }

    describe "ssh urls" do
      it "returns nil for other users" do
        assert_nil parser.browse_url("foo@gitorious.test:foo/bar.git", "sha123")
      end

      it "returns nil for other domains" do
        assert_nil parser.browse_url("git@github.com:foo/bar.git", "sha123")
      end

      it "returns repository url for matching protocol, port and domain" do
        assert_equal expected_url, parser.browse_url("git@gitorious.test:foo/bar.git", "sha123")
      end
    end

    describe "https urls" do
      it "returns nil for other ports" do
        assert_nil parser.browse_url("http://git.gitorious.test:8080/foo/bar.git", "sha123")
      end

      it "returns nil for other domains" do
        assert_nil parser.browse_url("http://git.github.com/foo/bar.git", "sha123")
      end

      it "returns repository url for matching protocol, port and domain" do
        assert_equal expected_url, parser.browse_url("http://gitorious.test/foo/bar.git", "sha123")
      end
    end

    describe "git urls" do
      it "returns nil for other ports" do
        assert_nil parser.browse_url("git://gitorious.test:8080/foo/bar.git", "sha123")
      end

      it "returns nil for other domains" do
        assert_nil parser.browse_url("git://github.com/foo/bar.git", "sha123")
      end

      it "returns repository url for matching protocol, port and domain" do
        assert_equal expected_url, parser.browse_url("git://gitorious.test/foo/bar.git", "sha123")
      end
    end

    describe "legacy urls" do
      it "returns repository url for legacy git url" do
        assert_equal expected_url, parser.browse_url("git://gitorious.test/~baz/foo/bar.git", "sha123")
      end

      it "returns repository url for legacy http url" do
        assert_equal expected_url, parser.browse_url("http://gitorious.test/~baz/foo/bar.git", "sha123")
      end

      it "returns repository url for legacy ssh url" do
        assert_equal expected_url, parser.browse_url("git@gitorious.test:+baz/foo/bar.git", "sha123")
      end
    end
  end
end
