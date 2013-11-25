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
require "test_helper"

class RepositoryBrowserTest < ActionDispatch::IntegrationTest
  setup do
    Repository.any_instance.stubs(:full_repository_path).returns(push_test_repo_path)
    repository = repositories(:johans)
    repository.ready = true
    repository.save!
  end

  should "render the repository files" do
    get "/johans-project/johansprojectrepos"
    follow_redirect!

    assert_response :success
  end

  should "render source of the requested file" do
    get "/johans-project/johansprojectrepos/source/ec433174463a9d0dd32700ffa5bbb35cfe2a4530:README"

    assert_response :success
  end

  should "render 404 repository page when requested file doesn't exist" do
    get "/johans-project/johansprojectrepos/source/ec433174463a9d0dd32700ffa5bbb35cfe2a4530:nonexistent.txt"

    assert_response :not_found
  end

  should "redirect to sha download url when ref (branch/tag) requested" do
    get "/johans-project/johansprojectrepos/archive/master.tgz"

    assert_redirected_to '/johans-project/johansprojectrepos/archive/ec433174463a9d0dd32700ffa5bbb35cfe2a4530.tgz'
  end
end
