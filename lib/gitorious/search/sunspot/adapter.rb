# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

module Gitorious
  module Search
    module Sunspot
      module Adapter
        def is_indexed
          searchable do
            yield Helper.new(self)
          end
        end
      end

      class Helper
        def initialize(searchable)
          @searchable = searchable
        end

        # TODO: Support conditions
        def conditions(*args)
        end

        def index(attribute, options={})
          case attribute
          when String
            index_relation(attribute, options)
          else
            index_single_attribute(attribute)
          end
        end

        def index_relation(attribute, options)
          object_name, field = attribute.split("#")
          @searchable.send(:text, options[:as]) do
            lambda { @searchable.send(object_name).send(field) }
          end
        end

        def index_single_attribute(attribute)
          @searchable.send(:text, attribute)
        end        
      end
    end
  end
end
