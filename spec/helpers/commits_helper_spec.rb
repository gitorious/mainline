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
      @stat_data = {:files=>
        {"spec/database_spec.rb"=>{:insertions=>5, :deletions=>12},
         "spec/integration/database_integration_spec.rb"=>
          {:insertions=>2, :deletions=>2},
         "lib/couch_object/document.rb"=>{:insertions=>2, :deletions=>2},
         "lib/couch_object/database.rb"=>{:insertions=>5, :deletions=>5},
         "spec/database_spec.rb.orig"=>{:insertions=>0, :deletions=>173},
         "bin/couch_ruby_view_requestor"=>{:insertions=>2, :deletions=>2}},
       :total=>{:files=>6, :insertions=>16, :deletions=>196, :lines=>212}}
       @stats = Grit::Stats.new(mock("Grit::Repo"), @stat_data[:total], @stat_data[:files])
    end
    
    it "renders a list of files as anchor links" do
      files = @stats.files.keys
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
