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

require "test_helper"

class RoutingIntegrationTest < ActionController::IntegrationTest
  should "redirect /users/user to /~user" do
    get "/users/zmalltalker"
    assert_redirected_to "/~zmalltalker"

    get "/users/zmall.talker"
    assert_redirected_to "/~zmall.talker"

    get "/users/zmall.talker/edit"
    assert_redirected_to "/~zmall.talker/edit"
  end

  should "redirect temporary tarball routes" do
    get "/gitorious/mainline/archive-tarball/master"
    assert_redirected_to "/gitorious/mainline/archive/master.tar.gz"
  end

  should "redirect user repository to project repository" do
    user = users(:johan)
    repository = user.repositories.first
    get "/~#{user.to_param}/#{repository.to_param}"

    assert_redirected_to "/#{repository.project.to_param}/#{repository.to_param}"
  end

  should "redirect group repository to project repository" do
    group = groups(:team_thunderbird)
    repository = group.repositories.first
    get "/+#{group.to_param}/#{repository.to_param}"

    assert_redirected_to "/#{repository.project.to_param}/#{repository.to_param}"
  end
end
