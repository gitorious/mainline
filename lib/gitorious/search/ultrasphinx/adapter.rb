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
    module Ultrasphinx
      module Adapter

        # This is where we get to work. Example:
        # is_indexed do |search|
        #   search.index :name
        #   search.index "user#login", :as => :username
        #   search.conditions => "status != 'rejected'"
        #   search.index :status_tag, :as => "status"
        #   search.collect :name, :from => "Tag", :as => "category", :using => "LEFT OUTER JOIN other TABLE ON..."
        # end
        
        def is_indexed(options={})
          helper = SearchHelper.new do |h|
            yield h if block_given?
          end
          options = helper.options
          is_indexed_ultrasphinx(options)
        end
      end
    end
  end
end
