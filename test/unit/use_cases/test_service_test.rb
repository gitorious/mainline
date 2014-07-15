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
require "test_service"

class TestServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:johan)
    @repository = @user.repositories.first
    @hook = create_web_hook({
        :repository => @repository,
        :url => "http://somewhere",
        :user => @user
      })
    Rugged::Repository.stubs(:new).returns(FakeRuggedRepository.new)
  end

  should "process web hook generator" do
    generator = Object.new
    generator.expects(:generate!)
    spec = Object.new
    PushSpecParser.expects(:new).with("a" * 40, "b" * 40, "refs/heads/master").returns(spec)
    Gitorious::ServicePayloadGenerator.expects(:new).with(@repository, spec, @user).returns(generator)
    outcome = TestService.new(Gitorious::App, @hook, @user).execute

    assert outcome.success?, outcome.failure.inspect
  end

  should "fail if user is not a repository admin" do
    outcome = TestService.new(Gitorious::App, @hook, users(:moe)).execute

    refute outcome.success?
    assert outcome.pre_condition_failed?
  end
end
