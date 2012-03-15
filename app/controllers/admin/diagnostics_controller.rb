# encoding: utf-8
#--
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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
class Admin::DiagnosticsController < ApplicationController

  def index
    @queues_up = markup queues_up?
    @git_operations_work = markup git_operations_work?
  end

  def summary
    if everything_healthy?
      render :text => "OK"
    else
      render :text => "One or several problems, see /admin/diagnostics for diagnostic overview", :status => 500
    end
  end  

  def markup(status)
    if status == true
      "<span class='diagnostic-true-indicator'>true</span>"
    else
      "<span class='diagnostic-false-indicator'>false</span>"
    end
  end

  
  # expand and move to lib/
  def everything_healthy?
    git_operations_work? && queues_up?
  end

  def git_operations_work?
    true
  end

  def queues_up?
    true
  end
    
end
