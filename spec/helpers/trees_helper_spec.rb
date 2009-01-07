#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

require File.dirname(__FILE__) + '/../spec_helper'

describe TreesHelper do
  
  include TreesHelper
  
  it "includes the RepostoriesHelper" do
    included_modules = (class << helper; self; end).send(:included_modules)
    included_modules.should include(RepositoriesHelper)
  end
  
  describe "commit_for_tree_path" do
    it "fetches the most recent commit from the path" do
      repo = mock("repository")
      git = mock("Git")
      repo.should_receive(:git).and_return(git)
      git.should_receive(:log).and_return([mock("commit")])
      commit_for_tree_path(repo, "foo/bar/baz.rb")
    end
  end
  
  it "has a current_path based on the *path glob" do
    params[:path] = ["one", "two"]
    current_path.should == ["one", "two"]
  end
  
  it "builds a tree from current_path" do
    params[:path] = ["one", "two"]
    build_tree_path("three").should == ["one", "two", "three"]
  end
  
end
