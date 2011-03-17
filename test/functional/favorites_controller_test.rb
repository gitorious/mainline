# encoding: utf-8
#--
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

require File.dirname(__FILE__) +  '/../test_helper'

class FavoritesControllerTest < ActionController::TestCase
  should_enforce_ssl_for(:delete, :destroy)
  should_enforce_ssl_for(:get, :index)
  should_enforce_ssl_for(:get, :update)
  should_enforce_ssl_for(:post, :create)
  should_enforce_ssl_for(:put, :update)

  def do_create_post(type, id, extra_options={})
    post :create, extra_options.merge(:watchable_type => type,
      :watchable_id => id)
  end

  context "Creating a new favorite" do
    setup {
      login_as :johan
      @repository = repositories(:johans2)
    }

    should "require login" do
      session[:user_id] = nil
      post :create
      assert_redirected_to new_sessions_path
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

    should "create a favorite" do
      do_create_post(@repository.class.name, @repository.id)
      assert_not_nil(favorite = assigns(:favorite))
    end

    should "redirect to the watchable itself" do
      do_create_post(@repository.class.name, @repository.id)
      assert_redirected_to([@repository.owner, @repository.project, @repository])
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
  end

  context "Deleting a favorite" do
    setup {
      login_as :johan
      @repository = repositories(:johans2)
      @favorite = users(:johan).favorites.create(:watchable => @repository)
    }

    should "assign to favorite" do
      delete :destroy, :id => @favorite
      assert_equal @favorite, assigns(:favorite)
    end

    should "redirect for HTML" do
      delete :destroy, :id => @favorite
      assert_redirected_to([@repository.owner, @repository.project, @repository])
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

  context "listing a users own favorites" do
    setup do
      @user = users(:mike)
      repositories(:johans).watched_by!(@user)
      login_as :mike
    end

    should "require login" do
      login_as nil
      get :index
      assert_redirected_to new_sessions_path
    end

    should "only list the users favorites" do
      assert @user.favorites.count > 0, "user has no favs"
      other_fav = Favorite.create!({:user => users(:johan),
          :watchable => Repository.last})
      get :index
      assert !assigns(:favorites).include?(other_fav)
      assert_equal @user.favorites, assigns(:favorites)
      assert_response :success
    end

    should "have a button to toggle the mail flag" do
      get :index
      assert_response :success
      assert_select "td.notification .favorite a.toggle"
    end

    should "have a button to delete the favorite" do
      get :index
      assert_response :success
      assert_select "td.unwatch .favorite a.watch-link"
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
      assert_response :redirect
      assert_redirected_to favorites_path
      assert @favorite.reload.notify_by_email?
    end

    should "only be able to change the mail flag" do
      assert !@favorite.notify_by_email?
      get :update, :id => @favorite.id, :favorite => {:user_id => users(:johan).id}
      assert_response :redirect
      assert_equal @user, @favorite.reload.user
    end
  end
end
