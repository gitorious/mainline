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

class CommitDiffsControllerTest < ActionController::TestCase
  include SampleRepoHelpers

  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @repository.update_attribute(:ready, true)
    @grit = sample_repo('test_repo')
    @from_id = @grit.commits.last.id
    @id = @grit.commits.first.id
    Repository.any_instance.stubs(:git).returns(@grit)
  end

  context "Comparing arbitrary commits" do
    should "pick the correct commits" do
      Grit::Commit.expects(:diff).with(@repository.git, @from_id, @id).returns([])
      get :show, params
      assert_response :success
    end

    should "render not found when given commit does not exist" do
      get :show, params.merge(:id => "does-not-exist")
      assert_response :not_found
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
    end

    should "disallow unauthorized access to show view" do
      get :show, params
      assert_response 403
    end

    should "allow authorized access to show view" do
      login_as :johan
      get :show, params
      assert_response 200
    end
  end

  context "With private repositories" do
    setup do
      enable_private_repositories(@repository)
    end

    should "disallow unauthorized access to show view" do
      get :show, params
      assert_response 403
    end

    should "allow authorized access to show view" do
      login_as :johan
      get :show, params
      assert_response 200
    end
  end

  private

  def params
    { :project_id => @project.slug,
      :repository_id => @repository.name,
      :from_id => @from_id,
      :id => @id,
      :fragment => "true" }
  end
end
