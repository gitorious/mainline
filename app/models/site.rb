# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
class Site < ActiveRecord::Base
  has_many :projects
  
  validates_presence_of :title
  HTTP_CLONING_SUBDOMAIN = 'git'
  validates_exclusion_of :subdomain, :in => [HTTP_CLONING_SUBDOMAIN]
  
  attr_protected :subdomain
  
  def self.default
    new(:title => "Gitorious", :subdomain => nil)
  end
end
