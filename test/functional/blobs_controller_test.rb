# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class BlobsControllerTest < ActionController::TestCase
  context "Blob rendering" do
    setup do
      @project = projects(:johans)
      @repository = @project.repositories.mainlines.first

      #Project.stubs(:find_by_slug!).with(@project.slug).returns(@project)
      #Repository.stubs(:find_by_name_and_project_id!).with(@repository.name, @project.id).returns(@repository)

      @git = stub_everything("Grit mock")
      Repository.any_instance.stubs(:git).returns(@git)
      @head = mock("master branch")
      @head.stubs(:name).returns("master")
      @repository.stubs(:head_candidate).returns(@head)
    end

    context "#show" do
      should "redirects to source" do
        get :show, :project_id => @project.to_param,
                   :repository_id => @repository.to_param,
                   :branch_and_path => "master/README"
        assert_redirected_to "/johans-project/johansprojectrepos/source/master:README"
      end
    end

    context "#blame" do
      should "redirects to new blame" do
        get :blame, :project_id => @project.to_param,
                    :repository_id => @repository.to_param,
                    :branch_and_path => "master/README"
        assert_redirected_to "/johans-project/johansprojectrepos/blame/master:README"
      end
    end

    context "#raw" do
      should "redirects to new raw" do
        get :raw, :project_id => @project.to_param,
                  :repository_id => @repository.to_param,
                  :branch_and_path => "master/README"
        assert_redirected_to "/johans-project/johansprojectrepos/raw/master:README"
      end
    end

    context "#history" do
      should "redirects to new tree history" do
        get :history, :project_id => @project.to_param,
                      :repository_id => @repository.to_param,
                      :branch_and_path => "master/README"
        assert_redirected_to "/johans-project/johansprojectrepos/tree_history/master:README"
      end
    end

    context "With private projects" do
      setup do
        enable_private_repositories(@project)
        @params = { :project_id => @project.slug,
          :repository_id => @repository.name,
          :branch_and_path => "master/README" }
      end

      should "reject user from show" do
        get :show, @params
        assert_response 403
      end

      should "allow owner to view blob" do
        login_as :johan
        get :show, @params
        assert_response 302
      end

      should "reject user from blame" do
        get :blame, @params
        assert_response 403
      end

      should "allow owner to view blame" do
        login_as :johan
        get :blame, @params
        assert_response 302
      end

      should "reject user from raw" do
        get :raw, @params
        assert_response 403
      end

      should "allow owner to view raw" do
        login_as :johan
        get :raw, @params
        assert_response 302
      end

      should "reject user from history" do
        get :history, @params
        assert_response 403
      end

      should "allow owner to view history" do
        login_as :johan
        get :history, @params
        assert_response 302
      end
    end

    context "With private repositories" do
      setup do
        enable_private_repositories(@repository)
        @params = { :project_id => @project.slug,
                    :repository_id => @repository.name,
                    :branch_and_path => "master/README" }
      end

      should "reject user from show" do
        get :show, @params
        assert_response 403
      end

      should "allow owner to view blob" do
        login_as :johan
        get :show, @params
        assert_response 302
      end

      should "reject user from blame" do
        get :blame, @params
        assert_response 403
      end

      should "allow owner to view blame" do
        login_as :johan
        get :blame, @params
        assert_response 302
      end

      should "reject user from raw" do
        get :raw, @params
        assert_response 403
      end

      should "allow owner to view raw" do
        login_as :johan
        get :raw, @params
        assert_response 302
      end

      should "reject user from history" do
        get :history, @params
        assert_response 403
      end

      should "allow owner to view history" do
        login_as :johan
        get :history, @params
        assert_response 302
      end
    end
  end
end
