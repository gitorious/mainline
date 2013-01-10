# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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
require "gitorious/view/dolt_url_helper"

class BlobsController < ApplicationController
  include Gitorious::View::DoltUrlHelper
  before_filter :find_project_and_repository

  def show
    ref, path = branch_and_path(params[:branch_and_path], @repository.git)
    redirect_to(blob_url(@repository.path_segment, ref, path.join("/")))
  end

  def blame
    ref, path = branch_and_path(params[:branch_and_path], @repository.git)
    redirect_to(blame_url(@repository.path_segment, ref, path.join("/")))
  end

  def raw
    ref, path = branch_and_path(params[:branch_and_path], @repository.git)
    redirect_to(raw_url(@repository.path_segment, ref, path.join("/")))
  end

  def history
    ref, path = branch_and_path(params[:branch_and_path], @repository.git)
    redirect_to(tree_history_url(@repository.path_segment, ref, path.join("/")))
  end
end
