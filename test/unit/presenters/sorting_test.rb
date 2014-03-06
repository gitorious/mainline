# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

class SortingTest < Minitest::Spec
  def sorting(order, view_context = nil)
    Sorting.new(order, view_context,
      {name: "foo", order: ->(q){ :foo }},
      {name: "bar", order: ->(q){ :bar }, default: true})
  end

  describe "#apply" do
    it "applies a matching scope" do
      assert_equal :foo, sorting("foo").apply(nil)
    end

    it "applies a default scope with no sorting found" do
      assert_equal :bar, sorting("baz").apply(nil)
    end
  end

  it "exposes current_order" do
    assert_equal "foo", sorting("foo").current_order
  end

  describe "#render_widget" do
    include ViewContextHelper

    it "disables the selected sort" do
      widget = sorting("foos", view_context).render_widget

      assert_includes widget, "?order=foo"
      refute_includes widget, "?order=bar"
    end
  end
end
