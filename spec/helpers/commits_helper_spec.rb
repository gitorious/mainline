require File.dirname(__FILE__) + '/../spec_helper'

describe CommitsHelper do
  
  it "includes the RepostoriesHelper" do
    self.class.ancestors.should include(RepositoriesHelper)
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
      rendered_stats = render_diff_stats(@stats)
      files.each do |filename|
        rendered_stats.should include(%Q{<li><a href="##{h(filename)}">#{h(filename)}</a>})
      end
    end
    
    it "renders a graph of minuses for deletions" do
      render_diff_stats(@stats).should include(%Q{spec/database_spec.rb</a>&nbsp;17&nbsp;<small class="deletions">#{"-"*12}</small>})
    end
    
    it "renders a graph of plusses for inserts" do
      render_diff_stats(@stats).should match(
        /spec\/database_spec\.rb<\/a>&nbsp;17&nbsp;<small class="deletions.+<\/small><small class="insertions">#{"\\+"*5}<\/small>/
      )
    end
  end

end
