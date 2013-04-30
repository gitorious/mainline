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
require "test_helper"

class UserWatchlistsControllerTest < ActionController::TestCase
  def teardown
    Rails.cache.clear
  end

  should "render activities watched by the user" do
    get :show, :id => users(:johan).to_param, :format => "atom"
    assert_response :success
  end

  should "not fail rendering feed when an event's user is nil" do
    repository = repositories(:johans)
    repository.project.events.create!({
        :action => Action::DELETE_TAG,
        :target => repository,
        :user => nil,
        :user_email => "marius@gitorious.com",
        :body => "Bla bla",
        :data => "A string of some kind"
      })

    get :show, :id => users(:johan).to_param, :format => "atom"

    assert_response :success
  end
end
