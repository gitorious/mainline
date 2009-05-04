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
class Role < ActiveRecord::Base
  KIND_ADMIN = 0
  KIND_MEMBER = 1
  
  include Comparable
  
  # TODO: use this when we upgrade to rails 2.3, and nuke the ::all override
  # default_scope :order => 'kind desc'
  
  def self.all
    find(:all, :order => 'kind desc')
  end
  
  def self.admin
    find_by_kind(KIND_ADMIN)
  end
  
  def self.member
    find_by_kind(KIND_MEMBER)
  end
  
  def admin?
    kind == KIND_ADMIN
  end
  
  def member?
    kind == KIND_MEMBER
  end  
  
  def  <=>(another_role)
    another_role.kind <=> kind
  end
end
