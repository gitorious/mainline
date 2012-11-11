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
require "mocha"

# Use this class in old test cases that dpeends on Shoulda.
# http://metaskills.net/2011/01/25/from-test-unit-shoulda-to-minitest-spec-minishoulda/
module MiniTest
  class Shoulda < MiniTest::Spec
    class << self
      alias :setup :before unless defined?(Rails)
      alias :teardown :after unless defined?(Rails)
      alias :should :it
      alias :context :describe
    end

    alias :assert_no_match :refute_match
    alias :assert_not_nil :refute_nil
    alias :assert_not_equal :refute_equal

    def assert_nothing_raised(&block)
      block.call # this assertion no longer exists!
    end

    def self.should_eventually(desc)
      it("should eventually #{desc}") { skip("Should eventually #{desc}") }
    end
  end
end

# Constants used throughout
NULL_SHA = "0" * 40
SHA = "a" * 40
OTHER_SHA = "a" * 40

# Rails shims
class NilClass; def blank?; true; end; end
class Array; def blank?; self.count == 0; end; end
class TrueClass; def blank?; false; end; end
class FalseClass; def blank?; true; end; end

class String
  def blank?; self == ""; end

  def constantize
    self.split("::").inject(Object) do |mod, name|
      mod.const_get(name)
    end
  end
end

class Array
  def sum(&block)
    self.inject(0) { |s, n| s + block.call(n) }
  end
end

class Fixnum
  def days; self * 24 * 60 * 60; end
  def day; days; end
  def ago; Time.now - self; end
end
