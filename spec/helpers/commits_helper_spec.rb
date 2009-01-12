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

describe CommitsHelper do
  
  it "includes the RepostoriesHelper" do
    included_modules = (class << helper; self; end).send(:included_modules)
    included_modules.should include(RepositoriesHelper)
  end
  
  describe "render_diff_stats" do
    before(:each) do
      @stat_data = [
        ["spec/database_spec.rb", 5, 12, 17],
        ["spec/integration/database_integration_spec.rb", 2, 2, 0],
      ]
      @stats = Grit::CommitStats.new(mock("Grit::Repo"), "a"*40, @stat_data)
    end
    
    it "renders a list of files as anchor links" do
      files = @stats.files.map{|f| f[0] }
      rendered_stats = helper.render_diff_stats(@stats)
      files.each do |filename|
        rendered_stats.should include(%Q{<li><a href="##{h(filename)}">#{h(filename)}</a>})
      end
    end
    
    it "renders a graph of minuses for deletions" do
      helper.render_diff_stats(@stats).should include(%Q{spec/database_spec.rb</a>&nbsp;17&nbsp;<small class="deletions">#{"-"*12}</small>})
    end
    
    it "renders a graph of plusses for inserts" do
      helper.render_diff_stats(@stats).should match(
        /spec\/database_spec\.rb<\/a>&nbsp;17&nbsp;<small class="deletions.+<\/small><small class="insertions">#{"\\+"*5}<\/small>/
      )
    end
  end

end
