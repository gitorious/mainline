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
require "repository_json_presenter"

class App
  def initialize(hash = {})
    @is_admin = hash[:is_admin]
    @display_ssh_url = hash[:display_ssh_url]
  end

  def admin?(user, repository); @is_admin; end
  def edit_project_repository_path(p, r); "/#{p.to_param}/#{r.to_param}/edit"; end
  def confirm_delete_project_repository_path(p, r); "/#{p.to_param}/#{r.to_param}/confirm_delete"; end
  def transfer_ownership_project_repository_path(p, r); "/#{p.to_param}/#{r.to_param}/ownership/edit"; end
  def project_repository_committerships_path(p, r); "/#{p.to_param}/#{r.to_param}/committerships"; end
  def project_repository_services_path(p, r); "/#{p.to_param}/#{r.to_param}/services"; end
  def favorites_path(h); "/favorites"; end
  def favorite_path(f); "/favorites/#{f.to_param}"; end
  def clone_project_repository_path(p, r); "/#{p.to_param}/#{r.to_param}/clone"; end
  def new_project_repository_merge_request_path(p, r); "/#{p.to_param}/#{r.to_param}/merge_requests/new"; end
  def description(repo); repo.description; end
end

class RepositoryJSONPresenterTest < MiniTest::Spec
  before do
    @repository = Repository.new({
        :name => "My repo",
        :description => "Really, it's my repo",
        :to_param => "repo",
        :project => Project.new(:to_param => "project")
      })
    def @repository.git_cloning?; true; end
    def @repository.http_cloning?; true; end
    def @repository.display_ssh_url?(user); false; end
    def @repository.default_clone_protocol; "git"; end
    @user = User.new
    def @user.favorites; []; end
  end

  describe "#hash_for" do
    it "indicates that user is not an administrator for the repository" do
      presenter = RepositoryJSONPresenter.new(App.new(:is_admin => false), @repository)

      assert !presenter.hash_for(@user)["repository"]["administrator"]
    end

    it "indicates that user is an administrator for the repository" do
      presenter = RepositoryJSONPresenter.new(App.new(:is_admin => true), @repository)

      refute_nil presenter.hash_for(@user)["repository"]["administrator"]
    end

    it "includes repository admin URLs" do
      presenter = RepositoryJSONPresenter.new(App.new(:is_admin => true), @repository)

      paths = presenter.hash_for(@user)["repository"]["admin"]
      assert_equal "/project/repo/edit", paths["editPath"]
      assert_equal "/project/repo/confirm_delete", paths["destroyPath"]
      assert_equal "/project/repo/ownership/edit", paths["ownershipPath"]
      assert_equal "/project/repo/committerships", paths["committershipsPath"]
      assert_equal "/project/repo/services", paths["servicesPath"]
    end

    it "includes repository name and description" do
      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      repository = presenter.hash_for(nil)["repository"]
      assert_equal "My repo", repository["name"]
      assert_equal "Really, it's my repo", repository["description"]
    end

    it "indicates that user watches repository" do
      def @user.favorites;
        f = Object.new
        def f.find;
          o = Object.new
          def o.to_param; "favorite"; end
          o
        end
        f
      end

      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      watch = {
        "watching" => true,
        "watchPath" => "/favorites",
        "unwatchPath" => "/favorites/favorite"
      }
      assert_equal watch, presenter.hash_for(@user)["repository"]["watch"]
    end

    it "indicates that user can watch repository" do
      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      watch = { "watching" => false, "watchPath" => "/favorites" }
      assert_equal watch, presenter.hash_for(@user)["repository"]["watch"]
    end

    it "indicates available clone protocols" do
      def @repository.display_ssh_url?(user); true; end
      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      protocols = presenter.hash_for(@user)["repository"]["cloneProtocols"]
      assert_equal ["git", "http", "ssh"], protocols["protocols"]
      assert_equal "ssh", protocols["default"]
    end

    it "includes clone URL" do
      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      repository = presenter.hash_for(@user)["repository"]
      assert_equal "/project/repo/clone", repository["clonePath"]
    end

    it "does not include clone URL for own repo clone" do
      @repository.owner = @user
      @repository.parent = Object.new

      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      repository = presenter.hash_for(@user)["repository"]
      assert_nil repository["clonePath"]
    end

    it "includes request merge path" do
      def @repository.parent; Repository.new(:to_param => "parent"); end
      @repository.owner = @user

      presenter = RepositoryJSONPresenter.new(App.new(:is_admin => true), @repository)

      repository = presenter.hash_for(@user)["repository"]
      assert_equal "/project/repo/merge_requests/new", repository["requestMergePath"]
    end

    it "does not include request merge path for non-clone" do
      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      repository = presenter.hash_for(@user)["repository"]
      assert_nil repository["requestMergePath"]
    end

    it "does not include request merge path for repo not admined by user" do
      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      repository = presenter.hash_for(@user)["repository"]
      assert_nil repository["requestMergePath"]
    end

    it "indicates available clone protocols for non-owner" do
      def @repository.display_ssh_url?(user); false; end
      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      protocols = presenter.hash_for(@user)["repository"]["cloneProtocols"]
      assert_equal ["git", "http"], protocols["protocols"]
      assert_equal "git", protocols["default"]
    end

    it "includes count of the open merge requests" do
      @repository.open_merge_requests = ['mr1', 'mr2', 'mr3']
      presenter = RepositoryJSONPresenter.new(App.new, @repository)

      repository = presenter.hash_for(@user)["repository"]
      assert_equal 3, repository["openMergeRequestCount"]
    end
  end
end
