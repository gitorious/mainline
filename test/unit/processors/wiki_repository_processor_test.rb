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

class WikiRepositoryCreationProcessorTest < ActiveSupport::TestCase
  def setup
    @parent = repositories(:moes)
    @repository = Repository.new({
        :parent => @parent,
        :name => "tracking",
        :kind => Repository::KIND_WIKI,
        :project => @parent.project
      })
    @repository.save!
    @processor = WikiRepositoryCreationProcessor.new
  end

  should "create git repository" do
    RepositoryHooks.stubs(:create)
    GitBackend.expects(:create).with("/tmp/git/repositories/moes-project/tracking.git")
    @processor.on_message("id" => @repository.id)
  end

  should "create repository hooks" do
    RepositoryHooks.expects(:create)
    @processor.on_message("id" => @repository.id)
  end

  should "mark repository as ready" do
    @repository.ready = false
    @repository.save!
    @processor.on_message("id" => @repository.id)

    assert @repository.reload.ready?
  end
end
