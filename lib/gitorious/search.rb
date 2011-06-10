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

  # A thin layer on top of search engine backends
  module Search

    # Specify which search engine to use. This will make available methods for configuring searchable
    # fields: make_indexed in ActiveRecord::Base subclasses
    def self.use(adapter)
      @search_adapter = adapter
    end

    # When including Gitorious::Search into a class, we provide +make_searchable+ to the class,
    # which relies on this being implemented in the module providing search
    def self.included(klass)
      
      # Keep a reference to the unobtrusive is_indexed method from Ultrasphinx
      # The Ultrasphinx rake tasks greps files for calls to is_indexed
      # so we want to keep this
      klass.instance_eval do
        alias :is_indexed_ultrasphinx :is_indexed
      end
      
      klass.extend(@search_adapter)
    end
    
  end
end
