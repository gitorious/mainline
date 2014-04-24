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
require "fast_test_helper"
require "project_json_presenter"

class App
  def initialize(hash = {})
    @is_admin = hash[:is_admin]
    @display_ssh_url = hash[:display_ssh_url]
  end

  def admin?(user, project); @is_admin; end
  def site_admin?(user); @is_admin; end
  def edit_project_path(p); "/#{p.to_param}/edit"; end
  def edit_slug_project_path(p); "/#{p.to_param}/edit_slug"; end
  def confirm_delete_project_path(p); "/#{p.to_param}/confirm_delete"; end
  def transfer_ownership_project_path(p); "/#{p.to_param}/ownership/edit"; end
  def new_project_repository_path(p); "/#{p.to_param}/repositories/new"; end
  def project_project_memberships_path(p); "/#{p.to_param}/memberships"; end
  def edit_admin_project_oauth_settings_path(p); "/#{p.to_param}/oauth_settings"; end
end

class ProjectJSONPresenterTest < MiniTest::Spec
  before do
    @project = Project.new(:to_param => "project")
    @user = User.new
  end

  describe "#hash_for" do
    it "indicates that user is not an administrator for the project" do
      presenter = ProjectJSONPresenter.new(App.new(:is_admin => false), @project)

      assert !presenter.hash_for(@user)["project"]["administrator"]
    end

    it "indicates that user is an administrator for the project" do
      presenter = ProjectJSONPresenter.new(App.new(:is_admin => true), @project)

      refute_nil presenter.hash_for(@user)["project"]["administrator"]
    end

    it "includes project admin URLs" do
      presenter = ProjectJSONPresenter.new(App.new(:is_admin => true), @project)

      paths = presenter.hash_for(@user)["project"]["admin"]
      assert_equal "/project/edit", paths["editPath"]
      assert_equal "/project/edit_slug", paths["editSlugPath"]
      assert_equal "/project/confirm_delete", paths["destroyPath"]
      assert_equal "/project/ownership/edit", paths["ownershipPath"]
      assert_equal "/project/repositories/new", paths["newRepositoryPath"]
    end

    it "does not include membership URL when private repos is disabled" do
      Gitorious.stubs(:private_repositories?).returns(false)
      presenter = ProjectJSONPresenter.new(App.new(:is_admin => true), @project)
      assert_nil presenter.hash_for(@user)["project"]["admin"]["membershipsPath"]
    end

    it "includes OAuth settings URL when this is gitorious.org" do
      Gitorious.stubs(:dot_org?).returns(true)
      presenter = ProjectJSONPresenter.new(App.new(:is_admin => true), @project)

      paths = presenter.hash_for(@user)["project"]["admin"]
      assert_equal "/project/oauth_settings", paths["oauthSettingsPath"]
    end

    it "includes membership URL when private repos is enabled" do
      Gitorious.stubs(:private_repositories?).returns(true)
      presenter = ProjectJSONPresenter.new(App.new(:is_admin => true), @project)
      assert_equal "/project/memberships", presenter.hash_for(@user)["project"]["admin"]["membershipsPath"]
    end
  end
end
