# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
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

require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  context "#favorites" do
    should "return open merge requests" do
      user = users(:johan)
      dashboard = Dashboard.new(user)
      merge_request = merge_requests(:moes_to_johans_open)
      favorite = merge_request.watched_by!(user)

      assert_include dashboard.favorites, favorite
    end

    should "not return closed merge requests" do
      user = users(:johan)
      dashboard = Dashboard.new(user)
      merge_request = merge_requests(:moes_to_johans_open)
      merge_request.close
      favorite = merge_request.watched_by!(user)

      assert_not_include dashboard.favorites, favorite
    end
  end
end

