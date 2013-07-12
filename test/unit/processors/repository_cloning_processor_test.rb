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
require "pathname"

class RepositoryCloningProcessorTest < ActiveSupport::TestCase
  def setup
    @parent = repositories(:moes)
    @repository = Repository.new({
        :parent => @parent,
        :name => "tracking",
        :kind => Repository::KIND_USER_REPO,
        :project => @parent.project
      })
    @repository.save!
    @processor = RepositoryCloningProcessor.new
    RepositoryCloner.stubs(:clone_with_hooks)
  end

  should "clone git repository with hooks" do
    RepositoryCloner.expects(:clone_with_hooks).with("b13/de7/574a4a04fb250257dcb5a7d6ef01dcf290.git", "moes-project/tracking.git")
    @processor.on_message("id" => @repository.id)
  end

  should "mark repository as ready" do
    @repository.ready = false
    @repository.save!
    @processor.on_message("id" => @repository.id)

    assert @repository.reload.ready?
  end

  should "mirror the repository cloning" do
    Gitorious.mirrors.expects(:clone_repository).with(@parent, @repository)
    @processor.on_message("id" => @repository.id)
  end

  should "copy disk usage information from the parent repository" do
    @parent.disk_usage = 123456
    @parent.save!
    @processor.on_message("id" => @repository.id)

    assert_equal 123456, @repository.reload.disk_usage
  end
end
