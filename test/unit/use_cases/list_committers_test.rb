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
require "list_committers"
require "gitorious/app"

class ListCommittersTest < ActiveSupport::TestCase
  def setup
    @app = Gitorious::App
  end

  should "return list of committers" do
    outcome = ListCommitters.new(@app, repositories(:johans), nil).execute

    assert outcome.success?
    assert_equal [users(:johan)], outcome.result
  end

  should "return list of committers filtered by access rights" do
    user = users(:johan)
    repository = repositories(:johans)
    @app.expects(:filter_authorized).with(user, @app.committers(repository))
    outcome = ListCommitters.new(@app, repository, user).execute

    assert outcome.success?
  end

  should "find repository by id" do
    outcome = ListCommitters.new(@app, repositories(:johans).id, nil).execute

    assert_equal [users(:johan)], outcome.result
  end

  should "fail if looking up non-existent repository" do
    outcome = ListCommitters.new(@app, -1, nil).execute

    assert_equal :repository_required, outcome.pre_condition_failed.symbol
    assert outcome.pre_condition_failed?
  end
end
