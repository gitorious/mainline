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

class DashboardPresenterTest < ActiveSupport::TestCase
  should "include user's commit repositories" do
    user = users(:johan)
    dashboard = Dashboard.new(user)
    authorized_filter = Gitorious::AuthorizedFilter.new(user)
    dashboard_presenter = DashboardPresenter.new(dashboard, authorized_filter, nil)

    assert_equal [repositories(:johans)], dashboard_presenter.repositories
  end

  should "not return unauthenticated repositories" do
    user = users(:mike)
    repositories(:johans).make_private

    dashboard = Dashboard.new(user)
    authorized_filter = Gitorious::AuthorizedFilter.new(user)
    dashboard_presenter = DashboardPresenter.new(dashboard, authorized_filter, nil)

    assert_equal [], dashboard_presenter.repositories
  end
end

