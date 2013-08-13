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

class ServiceTestsControllerTest < ActionController::TestCase
  def setup
    @repository = repositories(:johans)
    @project = @repository.project
    @web_hook = create_web_hook(
      :repository => @repository,
      :user => users(:johan),
      :url => "http://somewhere.com")
  end

  context "create" do
    should "test web hook for user" do
      login_as(:johan)
      outcome = UseCase::SuccessfulOutcome.new(@web_hook)
      TestService.any_instance.stubs(:execute).returns(outcome)

      post(:create, {
          :project_id => @project.to_param,
          :repository_id => @repository.to_param,
          :service_id => @web_hook.to_param
        })

      assert_response :redirect
      assert_equal "Payload sent to http://somewhere.com", flash[:notice]
    end

    should "render form and errors if unsuccessful" do
      login_as(:johan)
      outcome = UseCase::FailedOutcome.new(ServiceTestValidator.call(Repository.new))
      TestService.any_instance.stubs(:execute).returns(outcome)

      post(:create, {
          :project_id => @project.to_param,
          :repository_id => @repository.to_param,
          :service_id => @web_hook.to_param
        })

      assert_response :redirect
      assert_match "no commits", flash[:error]
    end
  end
end
