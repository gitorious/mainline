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

class RepositoryCreationProcessorTest < ActiveSupport::TestCase
   def setup
    GitBackend.stubs(:create)
    RepositoryHooks.stubs(:create)
    @repository = repositories(:moes)
    @processor = RepositoryCreationProcessor.new
    @gitdir = Pathname("/tmp/git/repos/moes-project/moesprojectrepos.git")
    RepositoryRoot.stubs(:expand).with("moes-project/moesprojectrepos.git").returns(@gitdir)
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
end
