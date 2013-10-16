# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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

class FavoritesControllerTest < ActionController::TestCase
  def setup
    setup_ssl_from_config
  end

  def do_create_post(type, id, options = {})
    url = options.fetch(:referer, 'http://gitorious.test/somewhere')
    request.env['HTTP_REFERER'] = url
    post :create, options.merge(:watchable_type => type, :watchable_id => id)
  end

  context "Creating a new favorite" do
    setup do
      login_as :johan
      @repository = repositories(:johans2)
    end

    should "require login" do
      session[:user_id] = nil
      post :create
      assert_redirected_to new_sessions_path
    end

    should "require authorized user when favoriting repository of private project" do
      enable_private_repositories(@repository.project)
      login_as :mike

      do_create_post(@repository.class.name, @repository.id)
      assert_response 403
    end

    should "require authorized user when favoriting private repository" do
      enable_private_repositories(@repository)
      login_as :moe

      do_create_post(@repository.class.name, @repository.id)
      assert_response 403
    end

    should "require authorized user when favoriting private project" do
      @project = @repository.project
      enable_private_repositories
      login_as :mike

      do_create_post(@project.class.name, @project.id)
      assert_response 403
    end

    should "assign to watchable" do
      do_create_post(@repository.class.name, @repository.id)
      assert_response :redirect
      assert_equal @repository, assigns(:watchable)
    end

    should "render not found when missing watchable" do
      do_create_post(@repository.class.name, 999)
      assert_response :not_found
    end

    should "render not found when invalid watchable type is provided" do
      do_create_post("RRepository", @repository.id)
      assert_response :not_found
    end

    should "render not found when boo watchable type is provided" do
      ::FakeWatchable = Class.new
      do_create_post("FakeWatchable", @repository.id)
      assert_response :not_found
    end

    should "create a favorite" do
      do_create_post(@repository.class.name, @repository.id)
      assert_not_nil assigns(:favorite)
    end

    should "redirect to the watchable itself" do
      url = project_repository_path(@repository.project, @repository)
      do_create_post(@repository.class.name, @repository.id, :referer => url)
      assert_redirected_to([@repository.project, @repository])
    end

    context "JS requests" do
      should "render :created" do
        do_create_post(@repository.class.name, @repository.id, {:format => "js"})
        assert_response :created
      end

      should "render :not_found" do
        do_create_post("Rrepository", @repository.id)
        assert_response :not_found
      end

      should "supply deletion URL in Location:" do
        do_create_post(@repository.class.name, @repository.id, {:format => "js"})
        assert_not_nil(favorite = assigns(:favorite))
        assert_equal("/favorites/#{favorite.id}", @response.headers["Location"])
      end
    end
  end

  context "Watching a merge request" do
    setup {
      login_as :johan
      @merge_request = merge_requests(:moes_to_johans)
    }

    should "create it" do
      do_create_post(@merge_request.class.name, @merge_request.id,
        {:format => "js"})
      assert_response :created
    end

    should "destroy it" do
      favorite = users(:johan).favorites.create(:watchable => @merge_request)
      delete :destroy, :id => favorite, :format => "js"
      assert_response :ok
    end

    should "not destroy it if not authorized" do
      login_as :moe
      favorite = users(:moe).favorites.create(:watchable => @merge_request)
      enable_private_repositories(@merge_request.source_repository)
      delete :destroy, :id => favorite, :format => "js"
      assert_response 403
    end
  end

  context "Deleting a favorite" do
    setup {
      user = users(:johan)
      login_as :johan
      @referer = user_edit_favorites_path(user)
      request.env['HTTP_REFERER'] = @referer
      @repository = repositories(:johans2)
      @favorite = user.favorites.create(:watchable => @repository)
    }

    should "assign to favorite" do
      delete :destroy, :id => @favorite
      assert_equal @favorite, assigns(:favorite)
    end

    should "redirect for HTML" do
      delete :destroy, :id => @favorite
      assert_redirected_to @referer
    end

    should "render :deleted for JS" do
      delete :destroy, :id => @favorite, :format => "js"
      assert_response :ok
    end

    should "supply re-creation URL in Location:" do
      delete :destroy, :id => @favorite, :format => "js"
      assert_equal(
        favorites_path(:watchable_id => @repository.id, :watchable_type => "Repository"),
        @response.headers["Location"])
    end

    should "delete the favorite" do
      delete :destroy, :id => @favorite
      assert_raises ActiveRecord::RecordNotFound do
        Favorite.find(@favorite.id)
      end
    end
  end

  context "editing a favorite" do
    setup do
      @user = users(:mike)
      login_as @user
      @favorite = Repository.last.watched_by!(@user)
    end

    should "scope the find to the user" do
      fav = Favorite.create!({:user => users(:johan),
          :watchable => Repository.last})
      put :update, :id => fav.id
      assert_response :not_found
    end

    should "be able to add the mail flag" do
      assert !@favorite.notify_by_email?
      get :update, :id => @favorite.id, :favorite => {:notify_by_email => true}
      assert_redirected_to user_edit_favorites_path(@user)
      assert @favorite.reload.notify_by_email?
    end

    should "only be able to change the mail flag" do
      assert !@favorite.notify_by_email?
      get :update, :id => @favorite.id, :favorite => {:user_id => users(:johan).id}
      assert_response :redirect
      assert_equal @user, @favorite.reload.user
    end

    should "disallow unauthorized users" do
      enable_private_repositories(@favorite.watchable)
      get :update, :id => @favorite.id, :favorite => {:user_id => users(:johan).id}
      assert_response 403
    end
  end
end
