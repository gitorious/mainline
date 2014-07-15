# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class Service::Adapter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :data

  def initialize(data)
    @data = data.presence || {}
  end

  def self.service_type
    name.split(':').last.underscore
  end

  def self.multiple?
    @multiple
  end

  def self.multiple
    @multiple = true
  end

  def self.label(value = nil)
    @label = value if value
    @label
  end

  def self.attributes(*names)
    names.each do |name|
      define_method(name) do
        data[name.to_sym] || data[name.to_s]
      end
    end
  end

  def id
    raise NotImplementedError
  end
end
