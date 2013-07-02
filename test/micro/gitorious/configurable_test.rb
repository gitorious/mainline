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
require "gitorious/configurable"

class ConfigurationTest < MiniTest::Spec
  before do
    @config = Gitorious::Configurable.new("MYLIB")
  end

  after do
    ENV.delete("MYLIB_THINGIE")
  end

  describe "append" do
    it "gets key from only settings set" do
      @config.append("prop" => 42)

      assert_equal 42, @config.get("prop")
    end

    it "gets key from first matching set" do
      @config.append("prop" => 42)
      @config.append("prop" => 12)

      assert_equal 42, @config.get("prop")
    end

    it "gets key from any matching set" do
      @config.append("something" => 42)
      @config.append("prop" => 12)

      assert_equal 12, @config.get("prop")
    end

    it "removes settings set" do
      settings = @config.append("prop" => 42)
      @config.append("prop" => 12)
      @config.prune(settings)

      assert_equal 12, @config.get("prop")
    end
  end

  describe "prepend" do
    it "gets key from only settings set" do
      @config.prepend("prop" => 42)

      assert_equal 42, @config.get("prop")
    end

    it "gets key from first matching set" do
      @config.prepend("prop" => 42)
      @config.prepend("prop" => 12)

      assert_equal 12, @config.get("prop")
    end

    it "gets key from any matching set" do
      @config.prepend("something" => 42)
      @config.prepend("prop" => 12)

      assert_equal 12, @config.get("prop")
    end

    it "removes settings set" do
      @config.prepend("prop" => 42)
      settings = @config.prepend("prop" => 12)
      @config.prune(settings)

      assert_equal 42, @config.get("prop")
    end
  end

  describe "environment variables" do
    it "prefers environment variable" do
      ENV["MYLIB_THINGIE"] = "use it!"
      @config.append("thingie" => 12)

      assert_equal "use it!", @config.get("thingie")
    end
  end

  describe "default values" do
    it "does not call default block if not needed" do
      @config.append("thingie" => 12)
      called = false
      value = @config.get("thingie") { called = true; 42 }

      assert_equal 12, value
      refute called
    end

    it "calls default block when no value available" do
      assert_equal 42, @config.get("blocked") { 42 }
    end

    it "does not use default callback when value is false" do
      @config.append("use_something" => false)
      assert_equal false, @config.get("use_something", true)
    end
  end

  describe "temporary configuration override" do
    it "temporarily disables regular configuration" do
      config = Gitorious::Configurable.new
      config.append(:one => 1, :two => 2)

      config.override(:one => 3) do |c|
        assert_equal 3, c.get(:one)
        assert_equal "Oops", c.get(:two, "Oops")
      end
    end

    it "restores original configuration after block" do
      config = Gitorious::Configurable.new
      config.append(:one => 1, :two => 2)

      config.override(:one => 3) { |c| }

      assert_equal 1, config.get(:one)
    end

    it "restores original configuration when block raises" do
      config = Gitorious::Configurable.new
      config.append(:one => 1, :two => 2)

      begin
        config.override(:one => 3) { |c| raise "Hell" }
      rescue
      end

      assert_equal 1, config.get(:one)
    end

    it "does not swallow block exceptions" do
      config = Gitorious::Configurable.new
      config.append(:one => 1, :two => 2)

      assert_raises(Hell) do
        config.override(:one => 3) { |c| raise Hell.new }
      end
    end
  end

  describe "deprecations" do
    before do
      @config = Gitorious::Configurable.new
    end

    it "looks up setting via deprecated key" do
      @config.rename("host_name", "host")
      @config.append("host_name" => "somewhere")

      assert_equal "somewhere", @config.get("host")
    end

    it "calls callback when using deprecated key" do
      args = []

      @config.on_deprecation do |key, new, comment|
        args = [key, new]
      end

      @config.rename("host_name", "host")
      @config.append("host_name" => "somewhere")
      host = @config.get("host")

      assert_equal ["host_name", "host"], args
    end

    it "does not call callback when using non-deprecated key" do
      args = []

      @config.on_deprecation do |key, new, comment|
        args = [key, new]
      end

      @config.rename("host_name", "host")
      @config.append("host" => "somewhere")
      host = @config.get("host")

      assert_equal [], args
    end

    it "does not call callback when using default for renamed key" do
      args = []

      @config.on_deprecation do |key, new, comment|
        args = [key, new]
      end

      @config.rename("host_name", "host")
      host = @config.get("host", "localhost")

      assert_equal [], args
    end

    it "calls block to transform deprecated value" do
      @config.rename("use_ssl", "scheme") { |use_ssl| "http#{use_ssl ? 's' : ''}" }
      @config.append("use_ssl" => true)

      assert_equal "https", @config.get("scheme")
    end
  end

  describe "group overrides" do
    it "gets group override" do
      config = Gitorious::Configurable.new
      config.append(:mysite => { :one => 1 })

      assert_equal 1, config.group_get(:mysite, :one)
    end

    it "gets global setting if no group override" do
      config = Gitorious::Configurable.new
      config.append(:one => 1)

      assert_equal 1, config.group_get(:mysite, :one)
    end

    it "gets default if no group override and no global" do
      config = Gitorious::Configurable.new
      config.append(:one => 1)

      assert_equal 42, config.group_get(:mysite, :two, 42)
    end

    it "gets default from block if no group override and no global" do
      config = Gitorious::Configurable.new
      config.append(:one => 1)

      assert_equal 42, config.group_get(:mysite, :two) { 42 }
    end

    it "gets global setting if group is nil" do
      config = Gitorious::Configurable.new
      config.append(:one => 1)

      assert_equal 1, config.group_get(nil, :one)
    end

    it "gets default if group is nil and no global" do
      config = Gitorious::Configurable.new
      config.append(:one => 1)

      assert_equal 42, config.group_get(nil, :two, 42)
    end

    it "gets default from block if group is nil and no global" do
      config = Gitorious::Configurable.new
      config.append(:one => 1)

      assert_equal 42, config.group_get(nil, :two) { 42 }
    end

    it "gets global if setting does not exist in group" do
      config = Gitorious::Configurable.new
      config.append(:mysite => { :one => 1 }, :two => 2)

      assert_equal 2, config.group_get(:mysite, :two)
    end

    it "gets setting from nested group" do
      config = Gitorious::Configurable.new
      config.append(:sites => { :mysite => { :one => 1 } })

      assert_equal 1, config.group_get([:sites, :mysite], :one)
    end

    it "gets default when sub-group is missing" do
      config = Gitorious::Configurable.new
      config.append(:sites => { :one => 1 })

      assert_equal 2, config.group_get([:sites, :mysite], :one, 2)
    end

    it "gets global when sub-group is missing" do
      config = Gitorious::Configurable.new
      config.append(:sites => { :one => 1 }, :one => 13)

      assert_equal 13, config.group_get([:sites, :mysite], :one, 2)
    end
  end
end

class Hell < RuntimeError; end
