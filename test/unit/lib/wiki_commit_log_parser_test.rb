# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
class WikiCommitLogParserTest < ActiveSupport::TestCase
  context "Parsing modified files from commit log" do
    setup do
      @parser = Gitorious::Wiki::CommitParser.new      
    end

    should "extract the details for a single commit" do
      output =<<COMMIT
commit e88d589c7c833152efeee05bf7e4b54e958be876
Author: Marius Mathiesen <marius@shortcut.no>

    Adding a hidden file here

A       Home.markdown
M       SomethingElse.markdown
COMMIT
      result = @parser.parse_commit(output.split("\n"))
      assert_equal "Adding a hidden file here", result.commit_message
      assert_equal "marius@shortcut.no", result.email
      assert_equal ["Home.markdown"], result.added_file_names
      assert_equal ["SomethingElse.markdown"], result.modified_file_names
    end
  end

  context "Parsing more that one commit" do
    setup do
      @output =<<COMMIT
commit e88d589c7c833152efeee05bf7e4b54e958be876
Author: Marius Mathiesen <marius@shortcut.no>

    Adding a hidden file here

A       Home.markdown
M       SomethingElse.markdown

commit fffdaa0
Author: Marius Mathiesen <marius@shortcut.no>

    Something else

M       Home.markdown
M       SomethingElse.markdown
COMMIT
    end

    should "extract 2 commit objects" do
      parser = Gitorious::Wiki::CommitParser.new
      result = parser.parse(@output)
      assert_equal 2, result.size
    end
  end

  context "With an actual repository" do
    setup do
      @parser = Gitorious::Wiki::CommitParser.new
      @grit = mock
      @git = mock(:git => @grit)
      @repo = mock(:git => @git)
    end

    should "call in to git to fetch the commit log" do
      output =<<COMMIT
commit e88d589c7c833152efeee05bf7e4b54e958be876
Author: Marius Mathiesen <marius@shortcut.no>

    Adding a hidden file here

A       Home.markdown
M       SomethingElse.markdown
M       NeverMind.markdown
COMMIT
      @grit.expects(:log).returns(output)
      spec = PushSpecParser.new(NULL_SHA, SHA, "refs/heads/master")
      result = @parser.fetch_from_git(@repo, spec).first
      assert_equal 2, result.modified_file_names.size
    end
  end

  context "Extracting the page name" do
    setup do
      @commit = Gitorious::Wiki::Commit.new
    end
    
    should "discard file suffix for added files" do
      @commit.added_file_names = ["Readme.markdown", "License.txt"]
      assert_equal %w(Readme License), @commit.added_page_names
    end

    should "discard file suffix for modified files" do
      @commit.modified_file_names = ["Readme.markdown", "License.txt"]
      assert_equal %w(Readme License), @commit.modified_page_names
    end

    should "behave when no added files exist" do
      assert_equal [], @commit.modified_page_names
    end

    should "not mark modified non-wiki files as wiki pages" do
      parser = Gitorious::Wiki::CommitParser.new
      result = parser.extract_modified_files_from_git_output("M    nevermind.markdown")
      assert_equal [], result
      result = parser.extract_modified_files_from_git_output("M    Nevermind.markdown")
      assert_equal ["Nevermind.markdown"], result
    end
  end
end
