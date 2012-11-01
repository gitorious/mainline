# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class SslRedirectionTest < ActionController::TestCase
  context "Admin::OauthSettingsController" do
    setup { @controller = Admin::OauthSettingsController.new }
    should_enforce_ssl_for(:get, :edit)
    should_enforce_ssl_for(:get, :show)
    should_enforce_ssl_for(:put, :update)
  end

  context "Admin::RepositoriesController" do
    setup { @controller = Admin::RepositoriesController.new }
    should_enforce_ssl_for(:get, :index)
    should_enforce_ssl_for(:put, :recreate, :id => 1)
  end

  context "Admin::UsersController" do
    setup { @controller = Admin::UsersController.new }
    should_enforce_ssl_for(:get, :index)
    should_enforce_ssl_for(:get, :new)
    should_enforce_ssl_for(:post, :create)
    should_enforce_ssl_for(:post, :reset_password, :id => "zmalltalker")
    should_enforce_ssl_for(:put, :suspend, :id => "zmalltalker")
    should_enforce_ssl_for(:put, :unsuspend, :id => "zmalltalker")
  end

  context "AliasesController" do
    setup { @controller = AliasesController.new }
    should_enforce_ssl_for(:get, :index, :user_id => "johan")
    should_enforce_ssl_for(:get, :new, :user_id => "johan")
    should_enforce_ssl_for(:post, :create, :user_id => "johan")
    should_enforce_ssl_for(:delete, :destroy, :user_id => "johan", :id => 1)
    should_enforce_ssl_for(:get, :confirm, :user_id => "johan", :id => 1)
  end

  context "CommentsController" do
    setup { @controller = CommentsController.new }
    should_enforce_ssl_for(:get, :index, :project_id => "p", :repository_id => "r")
    should_enforce_ssl_for(:get, :new, :project_id => "p", :repository_id => "r")
    should_enforce_ssl_for(:get, :create, :project_id => "p", :repository_id => "r")
    should_enforce_ssl_for(:post, :create, :project_id => "p", :repository_id => "r")
    should_enforce_ssl_for(:post, :preview, :project_id => "p", :repository_id => "r")
  end

  context "CommitsController" do
    setup { @controller = CommitsController.new }
    should_enforce_ssl_for(:get, :show, :project_id => "p", :repository_id => "r", :branch => "master")
    should_enforce_ssl_for(:get, :feed, :project_id => "p", :repository_id => "r", :branch => "master", :format => "atom")
    should_enforce_ssl_for(:get, :index, :project_id => "p", :repository_id => "r")
  end

  context "CommittershipsController" do
    setup { @controller = CommittershipsController.new }
    should_enforce_ssl_for(:delete, :destroy, :project_id => "p", :repository_id => "r", :id => 1)
    should_enforce_ssl_for(:get, :edit, :project_id => "p", :repository_id => "r", :id => 1)
    should_enforce_ssl_for(:get, :index, :project_id => "p", :repository_id => "r")
    should_enforce_ssl_for(:get, :new, :project_id => "p", :repository_id => "r")
    should_enforce_ssl_for(:get, :update, :project_id => "p", :repository_id => "r", :id => 1)
    should_enforce_ssl_for(:post, :create, :project_id => "p", :repository_id => "r")
  end

  context "EventsController" do
    setup { @controller = EventsController.new }
    should_enforce_ssl_for(:get, :commits)
  end

  context "FavoritesController" do
    setup { @controller = FavoritesController.new }
    should_enforce_ssl_for(:get, :index)
    should_enforce_ssl_for(:post, :create)
    should_enforce_ssl_for(:put, :update, :id => 1)
    should_enforce_ssl_for(:delete, :destroy, :id => 1)
  end

  context "GroupsController" do
    setup { @controller = GroupsController.new }
    should_enforce_ssl_for(:get, :index)
    should_enforce_ssl_for(:get, :new)
    should_enforce_ssl_for(:post, :create)
    should_enforce_ssl_for(:get, :show, :id => "+hackers")
    should_enforce_ssl_for(:get, :edit, :id => "+hackers")
    should_enforce_ssl_for(:put, :update, :id => "+hackers")
    should_enforce_ssl_for(:delete, :avatar, :id => "+hackers")
    should_enforce_ssl_for(:delete, :destroy, :id => "+hackers")
  end

  context "KeysController" do
    setup { @controller = KeysController.new }
    should_enforce_ssl_for(:get, :index, :user_id => "thomanil")
    should_enforce_ssl_for(:get, :new, :user_id => "thomanil")
    should_enforce_ssl_for(:post, :create, :user_id => "thomanil")
    should_enforce_ssl_for(:get, :show, :user_id => "thomanil", :id => 1)
    should_enforce_ssl_for(:delete, :destroy, :user_id => "thomanil", :id => 1)
  end

  context "LicensesController" do
    setup { @controller = LicensesController.new }
    should_enforce_ssl_for(:get, :show, :user_id => "zmalltalker")
    should_enforce_ssl_for(:get, :edit, :user_id => "zmalltalker")
    should_enforce_ssl_for(:put, :update, :user_id => "zmalltalker")
  end

  context "MembershipsController" do
    setup { @controller = MembershipsController.new }
    should_enforce_ssl_for(:get, :index, :group_id => "punchers")
    should_enforce_ssl_for(:get, :new, :group_id => "punchers")
    should_enforce_ssl_for(:post, :create, :group_id => "punchers")
    should_enforce_ssl_for(:get, :edit, :group_id => "punchers", :id => 1)
    should_enforce_ssl_for(:put, :update, :group_id => "punchers", :id => 1)
    should_enforce_ssl_for(:delete, :destroy, :group_id => "punchers", :id => 1)
  end

  context "MergeRequestsController" do
    setup { @controller = MergeRequestsController.new }

    def self.params(extra = {})
      { :project_id => "gitorious", :repository_id => "mainline" }.merge(extra)
    end

    should_enforce_ssl_for(:get, :index, params)
    should_enforce_ssl_for(:get, :new, params)
    should_enforce_ssl_for(:post, :create, params)
    should_enforce_ssl_for(:get, :oauth_return, params)
    should_enforce_ssl_for(:get, :show, params(:id => 1))
    should_enforce_ssl_for(:get, :edit, params(:id => 1))
    should_enforce_ssl_for(:get, :commit_status, params(:id => 1))
    should_enforce_ssl_for(:get, :direct_access, params(:id => 1))
    should_enforce_ssl_for(:get, :terms_accepted, params(:id => 1))
    should_enforce_ssl_for(:get, :version, params(:id => 1))
    should_enforce_ssl_for(:post, :commit_list, params(:id => 1))
    should_enforce_ssl_for(:post, :target_branches, params(:id => 1))
    should_enforce_ssl_for(:put, :update, params(:id => 1))
    should_enforce_ssl_for(:delete, :destroy, params(:id => 1))
  end

  context "MergeRequestVersionsController" do
    setup do
      @controller = MergeRequestVersionsController.new
      git = mock
      git.stubs(:git)
      Repository.any_instance.stubs(:git).returns(git)
    end

    should_enforce_ssl_for(:get, :show, {
                             :project_id => "p",
                             :repository_id => "r",
                             :merge_request_id => 1,
                             :id => 1
                           })
  end

  context "MessagesController" do
    setup { @controller = MessagesController.new }
    should_enforce_ssl_for(:get, :index)
    should_enforce_ssl_for(:get, :new)
    should_enforce_ssl_for(:post, :create)
    should_enforce_ssl_for(:get, :sent)
    should_enforce_ssl_for(:put, :bulk_update)
    should_enforce_ssl_for(:get, :all)
    should_enforce_ssl_for(:post, :auto_complete_for_message_recipients)
    should_enforce_ssl_for(:get, :read, :id => 1)
    should_enforce_ssl_for(:get, :reply, :id => 1)
    should_enforce_ssl_for(:get, :show, :id => 1)
    should_enforce_ssl_for(:post, :reply, :id => 1)
    should_enforce_ssl_for(:put, :read, :id => 1)
  end

  context "PagesController" do
    setup { @controller = PagesController.new }
    should_render_in_site_specific_context
    should_enforce_ssl_for(:get, :index, :project_id => "gts")
    should_enforce_ssl_for(:get, :show, :id => "page", :project_id => "gts")
    should_enforce_ssl_for(:get, :edit, :id => "page", :project_id => "gts")
    should_enforce_ssl_for(:put, :preview, :id => "page", :project_id => "gts")
    should_enforce_ssl_for(:get, :git_access, :id => "page", :project_id => "gts")
  end

  context "ProjectMembershipsController" do
    setup { @controller = ProjectMembershipsController.new }
    should_enforce_ssl_for(:get, :index, :project_id => "gts")
    should_enforce_ssl_for(:post, :create, :project_id => "gts")
    should_enforce_ssl_for(:delete, :destroy, :project_id => "gts", :id => 1)
  end

  context "ProjectsController" do
    setup { @controller = ProjectsController.new }
    should_enforce_ssl_for(:get, :index)
    should_enforce_ssl_for(:get, :new)
    should_enforce_ssl_for(:post, :create)
    should_enforce_ssl_for(:get, :show, :id => "gitorious")
    should_enforce_ssl_for(:get, :edit, :id => "gitorious")
    should_enforce_ssl_for(:put, :update, :id => "gitorious")
    should_enforce_ssl_for(:put, :preview, :id => "gitorious")
    should_enforce_ssl_for(:get, :edit_slug, :id => "gitorious")
    should_enforce_ssl_for(:put, :edit_slug, :id => "gitorious")
    should_enforce_ssl_for(:get, :clones, :id => "gitorious")
    should_enforce_ssl_for(:get, :confirm_delete, :id => "gitorious")
    should_enforce_ssl_for(:delete, :destroy, :id => "gitorious")
  end

  context "RepositoriesController" do
    setup { @controller = RepositoriesController.new }
    should_enforce_ssl_for(:get, :index, :project_id => "gts")
    should_enforce_ssl_for(:get, :new, :project_id => "gts")
    should_enforce_ssl_for(:post, :create, :project_id => "gts")
    should_enforce_ssl_for(:get, :show, :project_id => "gts", :id => "mainline")
    should_enforce_ssl_for(:get, :edit, :project_id => "gts", :id => "mainline")
    should_enforce_ssl_for(:put, :update, :project_id => "gts", :id => "mainline")
    should_enforce_ssl_for(:delete, :destroy, :project_id => "gts", :id => "mainline")
    should_enforce_ssl_for(:get, :clone, :project_id => "gts", :id => "mainline")
    should_enforce_ssl_for(:get, :confirm_delete, :project_id => "gts", :id => "mainline")
    should_enforce_ssl_for(:get, :search_clones, :project_id => "gts", :id => "mainline")
  end

  context "RepositoryMembershipsController" do
    setup { @controller = RepositoryMembershipsController.new }
    should_enforce_ssl_for(:get, :index, :project_id => "gts", :repository_id => "mainline")
    should_enforce_ssl_for(:post, :create, :project_id => "gts", :repository_id => "mainline")
    should_enforce_ssl_for(:delete, :destroy, :project_id => "gts", :repository_id => "mainline", :id => 1)
  end

  context "SearchesController" do
    setup { @controller = SearchesController.new }
    should_enforce_ssl_for(:get, :show)
  end
end
