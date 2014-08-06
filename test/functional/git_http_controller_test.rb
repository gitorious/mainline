# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

class GitHttpControllerTest < ActionController::TestCase

  context "GET, with command in service param" do
    # GET project/repo.git/info/refs?service=git-upload-pack

    should "respond with 404 for invalid repo path" do
      get :authorize,
        project_slug: 'foo',
        repository_name: 'nope',
        slug: '/info/refs',
        service: 'git-upload-pack'

      assert_response :not_found
    end

    context "when policy allows requested command" do
      setup do
        RepositoryPolicy.stubs(:allowed?).returns(true)
      end

      should "respond with 200" do
        assert_difference 'repositories(:johans).cloners.count', 1 do
          get :authorize,
            project_slug: 'johans-project',
            repository_name: 'johansprojectrepos',
            slug: '/info/refs',
            service: 'git-upload-pack'
        end

        assert_response :ok
        assert_equal response.headers['X-Accel-Redirect'], '/_internal/git/c2a/943/aad718337973577b555383db50ae03e01c.git/info/refs?service=git-upload-pack'

        # Ensure Content-Type doesn't include charset, which when appended by
        # Nginx to git-http-backend response headers causes error on client.
        assert_equal response.headers['Content-Type'], 'text/plain'
      end
    end

    context "when policy doesn't allow requested command" do
      setup do
        RepositoryPolicy.stubs(:allowed?).returns(false)
      end

      should "respond with 403 for valid credentials" do
        request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Basic.encode_credentials('johan', 'test')

        get :authorize,
          project_slug: 'johans-project',
          repository_name: 'johansprojectrepos',
          slug: '/info/refs',
          service: 'git-upload-pack'

        assert_response :forbidden
        assert_equal response.headers['Content-Type'], 'text/plain'
      end

      should "respond with 401 for invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Basic.encode_credentials('no', 'no')

        get :authorize,
          project_slug: 'johans-project',
          repository_name: 'johansprojectrepos',
          slug: '/info/refs',
          service: 'git-upload-pack'

        assert_response :unauthorized
        assert_match /invalid/i, response.body
        assert_equal response.headers['Content-Type'], 'text/plain'
      end

      should "respond with 401 for missing credentials" do
        get :authorize,
          project_slug: 'johans-project',
          repository_name: 'johansprojectrepos',
          slug: '/info/refs',
          service: 'git-upload-pack'

        assert_response :unauthorized
        assert_match /anonymous/i, response.body
        assert_equal response.headers['Content-Type'], 'text/plain'
      end
    end
  end

  context "POST, with command in slug param" do
    # POST project/repo.git/git-upload-pack

    should "respond with 404 for invalid repo path" do
      post :authorize,
        project_slug: 'foo',
        repository_name: 'nope',
        slug: '/git-upload-pack'

      assert_response :not_found
    end

    context "when policy allows requested command" do
      setup do
        RepositoryPolicy.stubs(:allowed?).returns(true)
      end

      should "respond with 200" do
        post :authorize,
          project_slug: 'johans-project',
          repository_name: 'johansprojectrepos',
          slug: '/git-upload-pack'

        assert_response :ok
        assert_equal response.headers['X-Accel-Redirect'], '/_internal/git/c2a/943/aad718337973577b555383db50ae03e01c.git/git-upload-pack'

        # Ensure Content-Type doesn't include charset, which when appended by
        # Nginx to git-http-backend response headers causes error on client.
        assert_equal response.headers['Content-Type'], 'text/plain'
      end
    end

    context "when policy doesn't allow requested command" do
      setup do
        RepositoryPolicy.stubs(:allowed?).returns(false)
      end

      should "respond with 403 for valid credentials" do
        request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Basic.encode_credentials('johan', 'test')

        post :authorize,
          project_slug: 'johans-project',
          repository_name: 'johansprojectrepos',
          slug: '/git-upload-pack'

        assert_response :forbidden
        assert_equal response.headers['Content-Type'], 'text/plain'
      end

      should "respond with 401 for invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Basic.encode_credentials('no', 'no')

        post :authorize,
          project_slug: 'johans-project',
          repository_name: 'johansprojectrepos',
          slug: '/git-upload-pack'

        assert_response :unauthorized
        assert_match /invalid/i, response.body
        assert_equal response.headers['Content-Type'], 'text/plain'
      end

      should "respond with 401 for missing credentials" do
        post :authorize,
          project_slug: 'johans-project',
          repository_name: 'johansprojectrepos',
          slug: '/git-upload-pack'

        assert_response :unauthorized
        assert_match /anonymous/i, response.body
        assert_equal response.headers['Content-Type'], 'text/plain'
      end
    end
  end

end
