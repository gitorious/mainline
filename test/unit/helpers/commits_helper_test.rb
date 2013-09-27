# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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

class CommitsHelperTest < ActionView::TestCase
  include ERB::Util

  should "includes the RepostoriesHelper" do
    included_modules = (class << self; self; end).send(:included_modules)
    assert included_modules.include?(RepositoriesHelper)
  end

  context "render_diff_stats" do
    setup do
      @stat_data = [
        ["spec/database_spec.rb", 5, 12, 17],
        ["spec/integration/database_integration_spec.rb", 2, 2, 0],
      ]
      @stats = Grit::CommitStats.new(mock("Grit::Repo"), "a"*40, @stat_data)
    end

    should "renders a list of files as anchor links" do
      files = @stats.files.map{|f| f[0] }
      rendered_stats = render_diff_stats(@stats)
      files.each do |filename|
        assert rendered_stats.include?(%Q{<li><a href="##{h(filename)}">#{h(filename)}</a>})
      end
    end

    should "renders a graph of minuses for deletions" do
      assert render_diff_stats(@stats).include?(%Q{spec/database_spec.rb</a> (17) <span class="gts-diff-rm">#{"-"*12}</span>})
    end
  end
end
