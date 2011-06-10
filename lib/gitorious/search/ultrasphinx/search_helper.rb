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
      class SearchHelper
        def initialize
          yield self
        end

        def options
          fields = arguments.select{|arg| !arg.association?}.map(&:arguments)
          associations = arguments.select(&:association?).map(&:arguments)
          result = {}
          result[:fields] = fields unless fields.blank?
          result[:include] = associations unless associations.blank?
          result[:conditions] = @conditions if @conditions
          result[:concatenate] = concatenations.map(&:arguments) unless concatenations.blank?
          result
        end

        def index(name, options={})
          arguments << Argument.new(name,options)
        end

        def collect(field, options)
          concatenations << Concatenation.new(field, options)
        end

        def concatenations
          @concatenations ||= []
        end

        def arguments
          @arguments ||= []
        end

        def conditions(conditions)
          @conditions = conditions
        end

        class Concatenation
          def initialize(field, options)
            @field = field
            @options = options
          end

          def arguments
            {
              :class_name => @options[:from],
              :field => @field.to_s,
              :as => @options[:as],
              :association_sql => @options[:using]
            }
          end
        end
        
        class Argument
          def initialize(name,options)
            @name = name
            @options = options
          end

          def method_name
            association? ? :include : :fields
          end

          def association?
            String === @name
          end

          def arguments
            association? ? association_arguments : field_arguments
          end

          def association_arguments
            name, method = @name.split("#")
            result = {:association_name => name, :field => method, :as => @options[:as].to_s}
            result
          end

          def field_arguments
            if @options[:as]
              {:field => @name.to_s, :as => @options[:as].to_s}
            else
              @name
            end
          end
        end
      end
    end
  end
end
