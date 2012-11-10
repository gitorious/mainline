# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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

class SslEnforcementTest < ActionController::IntegrationTest
  context "with SSL enabled" do
    setup do
      @test_settings = Gitorious::Configuration.prepend("use_ssl" => true)
    end

    teardown do
      Gitorious::Configuration.prune(@test_settings)
    end

    should "not redirect from https to http" do
      get "https://#{Gitorious.host}/projects"

      assert_response :success
    end

    should "not force https on repository configuration URL" do
      repo = repositories(:johans)
      project = repo.project

      get "http://#{Gitorious.host}/#{project.slug}/#{repo.name}/config"

      assert_response :success
    end
  end
end
