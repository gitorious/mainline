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

class MarshalableRelation
  # Extend active record relations with +marshal_dump+ and
  # +marshal_load+ methods that serializes the objects/relations as
  # JSON. This allows them to be cached with Rails.cache
  #
  def self.extend(relation, klass)
    (class << relation; self; end).send(:define_method, :marshal_dump) do
      { :class_name => klass.to_s, :entries => map(&:attributes).to_json }
    end

    def relation.marshal_load(dump)
      klass = Object.const_get(dump[:class_name])
      JSON.parse(dump[:attributes]).map { |attrs| klass.new(attrs) }
    end

    relation
  end
end
