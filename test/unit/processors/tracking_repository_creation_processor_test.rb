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

class TrackingRepositoryCreationProcessorTest < ActiveSupport::TestCase
  def setup
    @parent = repositories(:moes)
    @repository = Repository.new({
        :parent => @parent,
        :name => "tracking",
        :kind => Repository::KIND_TRACKING_REPO,
        :project => @parent.project
      })
    @repository.save!
    @processor = TrackingRepositoryCreationProcessor.new
  end

  should "clone git repository without hooks" do
    RepositoryCloner.expects(:clone).with("b13/de7/574a4a04fb250257dcb5a7d6ef01dcf290.git", "moes-project/tracking.git")
    @processor.on_message("id" => @repository.id)
  end
end
