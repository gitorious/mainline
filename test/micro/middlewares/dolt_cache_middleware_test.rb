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
require "minitest/autorun"
require "app/middlewares/dolt_cache_middleware"
require "fast_test_helper"
require "rack"

NO_CACHE = "max-age=0, private"


describe "Outside dolt" do
  before do
    @env = {}
    @app = NonDoltApp.new
    @middleware = DoltCacheMiddleware.new(@app)
  end

  it "stays away from the Cache-Control headers" do
    result = @middleware.call(@env)
    original_result = @app.call(@env)
    assert_equal result[1], original_result[1]
  end
end

describe "Inside dolt" do
  before do
    @env = {}
    @app = DoltApp.new
    @middleware = DoltCacheMiddleware.new(@app)
  end

  it "sets private Cache-Control headers" do
    result = @middleware.call(@env)
    assert_cache_header NO_CACHE, result
  end
end
