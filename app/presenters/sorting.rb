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

class Sorting
  attr_reader :current_order

  def initialize(current_order, view_context, template, *sorts)
    @template = template
    @current_order = current_order
    @v = view_context
    @sorts = sorts
  end

  def render_widget
    v.render(template, sorts: sorts, sorting: self)
  end

  def apply(query)
    current_sort[:order][query]
  end

  def current_sort?(sort)
    sort == current_sort
  end

  private

  attr_reader :v, :sorts, :template

  def current_sort
    sorts.find { |s| s[:name].to_s == current_order } ||
    sorts.find { |s| s[:default] } ||
    identity
  end

  def identity
    {order: ->(q) { q }}
  end
end
