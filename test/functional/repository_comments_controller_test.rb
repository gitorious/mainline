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
require "create_comment"

class RepositoryCommentsControllerTest < ActionController::TestCase
  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @repository.update_attribute(:ready, true)
    @user = users(:zmalltalker)
    Repository.any_instance.stubs(:has_commits?).returns(true)
    Repository.any_instance.stubs(:head_candidate_name).returns("master")
  end

  context "index" do
    should "list comments" do
      create_comment

      get :index, params(format: 'atom')

      assert_response 200
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
    end

    should "disallow unauthorized user from listing comments" do
      comment = create_comment
      get :index, params(format: 'atom')
      assert_response 403
    end

    should "allow authorized user to list comments" do
      login_as :johan
      comment = create_comment
      get :index, params(format: 'atom')
      assert_response 200
    end
  end

  private
  def create_comment
    CreateComment.new(@user, @repository).execute(:body => "Hey man!").result
  end

  def params(param = {})
    param.merge({
        :project_id => @project.to_param,
        :repository_id => @repository.to_param
      })
  end
end
