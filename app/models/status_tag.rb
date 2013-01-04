# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class StatusTag
  def initialize(name, project)
    @name = name
    @project = project
  end
  attr_reader :name, :project

  def to_s
    name
  end

  def status
    return nil if name.blank?
    project.merge_request_statuses.where("LOWER(name) = ?", name.downcase).first
  end

  def description
    status ? status.description : nil
  end

  def color
    status && !status.color.blank? ? status.color : "#cccccc"
  end

  def open?
    return false unless status
    status.open?
  end

  def closed?
    return false unless status
    status.closed?
  end

  def unknown_state?
    status ? false : true
  end
end
