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
    Sorting.new(order, view_context, 'foo/bar',
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

    it "returns the given collection with no default" do
      sorting = Sorting.new("foo", nil, 'foo/bar')
      assert_equal [1,2,3], sorting.apply([1,2,3])
    end
  end

  it "exposes current_order" do
    assert_equal "foo", sorting("foo").current_order
  end

  describe "#render_widget" do
    it "disables the selected sort" do
      sorts = [{name: 'foo'}]
      view_context = stub
      sorting = Sorting.new(:foo, view_context, 'foo/bar', *sorts)
      view_context.stubs(:render)
        .with('foo/bar', sorts: sorts, sorting: sorting)
        .returns("rendered template")

      assert_equal "rendered template", sorting.render_widget
    end
  end
end
