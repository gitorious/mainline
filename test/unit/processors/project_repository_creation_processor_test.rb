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

class ProjectRepositoryCreationProcessorTest < ActiveSupport::TestCase
  def setup
    GitBackend.stubs(:create)
    RepositoryHooks.stubs(:create)
    @repository = repositories(:moes)
    @processor = ProjectRepositoryCreationProcessor.new
    @gitdir = Pathname("/tmp/git/repos/b13/de7/574a4a04fb250257dcb5a7d6ef01dcf290.git")
    RepositoryRoot.stubs(:expand).with("b13/de7/574a4a04fb250257dcb5a7d6ef01dcf290.git").returns(@gitdir)
  end

  should "create git repository" do
    GitBackend.expects(:create).with(@gitdir.to_s)
    @processor.on_message("id" => @repository.id)
  end

  should "create repository hooks" do
    RepositoryHooks.expects(:create).with(@gitdir)
    @processor.on_message("id" => @repository.id)
  end

  should "mark repository as ready" do
    @repository.ready = false
    @repository.save!
    @processor.on_message("id" => @repository.id)

    assert @repository.reload.ready?
  end

  should "mirror the repository creation" do
    Repository.stubs(:find).with(@repository.id).returns(@repository)
    Gitorious.mirrors.expects(:init_repository).with(@repository)
    @processor.on_message("id" => @repository.id)
  end
end
