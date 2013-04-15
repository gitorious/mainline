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
require "search_clones"

class SearchClonesTest < ActiveSupport::TestCase
  def setup
    @app = mock("App")
    def @app.filter_authorized(user, collection); collection; end
    @repository = repositories(:johans)
    @user = @repository.user
  end

  should "return list of clones" do
    outcome = SearchClones.new(@app, @repository, users(:moe)).execute({})

    assert outcome.success?, outcome.to_s
    assert_equal [repositories(:johans2)], outcome.result
  end

  should "fail if user cannot access repository" do
    Gitorious.stubs(:private_repositories?).returns(true)
    @app.stubs(:can_read?).returns(false)
    outcome = SearchClones.new(@app, @repository, users(:moe)).execute({})

    assert outcome.pre_condition_failed?, outcome.to_s
    assert_equal :authorization_required, outcome.pre_condition_failed.symbol
  end

  should "exclude private repositories when searching clones" do
    clone = repositories(:johans2)
    @app.stubs(:can_read?).returns(true)
    @app.stubs(:filter_authorized).with(users(:moe), [clone]).returns([])

    outcome = SearchClones.new(@app, @repository, users(:moe)).execute({})

    assert outcome.success?, outcome.to_s
    assert_equal 0, outcome.result.length
  end
end
