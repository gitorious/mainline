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

require 'test_helper'

class FavoritesControllerTest < ActionController::TestCase
  def do_create_post(type, id, extra_options={})
    post :create, extra_options.merge(:watchable_type => type,
      :watchable_id => id)
  end
  
  context "Creating a new favorite" do
    setup {
      login_as :johan
      @repository = repositories(:johans)
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

    should "delete the favorite" do
      delete :destroy, :id => @favorite
      assert_raises ActiveRecord::RecordNotFound do
        Favorite.find(@favorite.id)
      end
    end

  end
end
