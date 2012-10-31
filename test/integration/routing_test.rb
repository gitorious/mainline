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

class RoutingTest < ActionController::IntegrationTest
  should "redirect /~user/project/repo to /project/repo" do
    get "/~zmalltalker/gitorious/mainline"
    assert_redirected_to "/gitorious/mainline"
  end

  should "redirect /~user/project/repo/action to /project/repo/action" do
    get "/~zmalltalker/gitorious/mainline/edit"
    assert_redirected_to "/gitorious/mainline/edit"
  end

  should "redirect /~user.name/project/repo/action to /project/repo/action" do
    get "/~zmall.talker/gitorious/mainline/edit"
    assert_redirected_to "/gitorious/mainline/edit"
  end

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

  should "redirect temporary user tarball routes" do
    get "/~zmalltalker/mainline/archive-tarball/master"
    assert_redirected_to "/~zmalltalker/mainline/archive/master.tar.gz"
  end

  should "redirect user scoped merge requests to project/repo/mr" do
    get "/~mc.hammer/myproject/myrepo/merge_requests"
    assert_redirected_to "/myproject/myrepo/merge_requests"
  end
end
