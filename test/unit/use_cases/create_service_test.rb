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
require "create_service"

class CreateServiceTest < ActiveSupport::TestCase
  should "create web hook" do
    user = users(:johan)
    outcome = CreateService.new(Gitorious::App, Repository.first, user).execute(
      :data => { :url => "http://example.com" },
      :service_type => Service::WebHook.service_type)

    assert outcome.success?, outcome.failure.inspect
    assert_equal Repository.first, outcome.result.repository
    assert_equal user, outcome.result.user
    assert_equal "http://example.com", outcome.result.adapter.url
  end

  should "fail if user is not a repository admin" do
    user = users(:johan)
    outcome = CreateService.new(Gitorious::App, repositories(:moes), user).execute(
      :data => { :url => "http://example.com" },
      :service_type => Service::WebHook.service_type)

    refute outcome.success?
    assert outcome.pre_condition_failed?
  end

  should "create site-wide web hook" do
    user = users(:johan)
    outcome = CreateService.new(Gitorious::App, repositories(:johans), user).execute(
      :data => { :url => "http://example.com" },
      :service_type => Service::WebHook.service_type,
      :site_wide => true)

    assert outcome.success?
    assert outcome.result.global?
  end
end
