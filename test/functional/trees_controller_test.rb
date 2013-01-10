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

class TreesControllerTest < ActionController::TestCase
  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @repository.update_attribute(:ready, true)

    grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(grit)
  end

  context "#index" do
    should "redirect to source root" do
      get :index, params
      assert_redirected_to "/johans-project/johansprojectrepos/source/master:"
    end
  end

  context "#show" do
    should "redirect to source view" do
      get :show, params(:branch_and_path => "master/lib/grit")

      assert_redirected_to "/johans-project/johansprojectrepos/source/master:lib/grit"
    end

    should "redirect slashed ref to source view" do
      get :show, params(:branch_and_path => "test/master/lib")

      assert_redirected_to "/johans-project/johansprojectrepos/source/test/master:lib"
    end
  end

  context "Archive downloads" do
    setup do
      @master_sha = "ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a"
      @test_master_sha = "2d3acf90f35989df8f262dc50beadc4ee3ae1560"
      @cached_path = File.join(Gitorious.archive_cache_dir,
                        "#{@repository.hashed_path.gsub(/\//, '-')}-#{@master_sha}.tar.gz")
      File.stubs(:exist?).with(@cached_path).returns(true)
    end

    should "redirect to archive action" do
      get :archive, params(:branch => %w[master], :archive_format => "tar.gz")

      assert_redirected_to "/johans-project/johansprojectrepos/archive/master.tar.gz"
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
    end

    should "disallow unauthorized users from listing trees" do
      get :index, params
      assert_response 403
    end

    should "allow authorized users to list trees" do
      login_as :johan
      get :index, params
      assert_response 302
    end

    should "disallow unauthorized users from showing tree" do
      get :show, params(:branch_and_path => "master/lib/grit")
      assert_response 403
    end

    should "allow authorized users to show tree" do
      login_as :johan
      get :show, params(:branch_and_path => "master/lib/grit")
      assert_not_equal "403", @response.code
    end

    should "disallow unauthorized users from showing archive" do
      get :archive, params(:branch => %w[master], :archive_format => "tar.gz")
      assert_response 403
    end

    should "allow authorized users to show archive" do
      login_as :johan
      get :archive, params(:branch => %w[master], :archive_format => "tar.gz")
      assert_not_equal "403", @response.code
    end
  end

  context "With private repositories" do
    setup do
      enable_private_repositories(@repository)
      @project.make_public
    end

    should "disallow unauthorized users from listing trees" do
      get :index, params
      assert_response 403
    end

    should "allow authorized users to list trees" do
      login_as :johan
      get :index, params
      assert_response 302
    end

    should "disallow unauthorized users from showing tree" do
      get :show, params(:branch_and_path => "master/lib/grit")
      assert_response 403
    end

    should "allow authorized users to show tree" do
      login_as :johan
      get :show, params(:branch_and_path => "master/lib/grit")
      assert_not_equal "403", @response.code
    end

    should "disallow unauthorized users from showing archive" do
      get :archive, params(:branch => %w[master], :archive_format => "tar.gz")
      assert_response 403
    end

    should "allow authorized users to show archive" do
      login_as :johan
      get :archive, params(:branch => %w[master], :archive_format => "tar.gz")
      assert_not_equal "403", @response.code
    end
  end

  private
  def params(data = {})
    { :project_id => @project.slug, :repository_id => @repository.name }.merge(data)
  end
end
