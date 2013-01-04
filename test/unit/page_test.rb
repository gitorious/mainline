# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
require "fileutils"

class PageTest < ActiveSupport::TestCase

  def setup
    @path = "/tmp/gts-test-wiki"
    delete_test_repo
    FileUtils.mkdir(@path)
    Dir.chdir(@path) do
      File.open("HowTo.markdown", "wb"){|f| f.puts "Hello world!" }
      ENV['GIT_COMMITTER_NAME'] = "Johan Sørensen"
      ENV['GIT_COMMITTER_EMAIL'] = "johan@johansorensen.com"
      `git init; git add .; git commit --author='Johan Sorensen <johan@johansorensen.com>' -m "first commit"`
    end
    @repo = Grit::Repo.new(@path)
  end

  def teardown
    delete_test_repo
  end

  should "finds an existing page" do
    page = Page.find("HowTo", @repo)
    assert !page.new?, 'page.new? should be false'
    assert_equal "HowTo.markdown", page.name
    assert_equal "Hello world!\n", page.content
  end

  should "raises an error when there is no user set" do
    p = Page.find("HowTo", @repo)
    assert_raises(Page::UserNotSetError) { p.save }
  end

  should "updates the content when calling save" do
    p = Page.find("HowTo", @repo)
    p.user = users(:johan)
    p.content = "bye cruel world!"
    assert_equal "bye cruel world!", p.content
    assert_match(/^[a-z0-9]{40}$/, p.save)
    p2 = Page.find("HowTo", @repo)
    assert_equal "bye cruel world!", p2.content
  end

  should "creates a new page" do
    p = Page.find("Hello", @repo)
    assert p.new?, 'p.new? should be true'
    assert_equal "", p.content
    p.user = users(:johan)
    assert_match(/^[a-z0-9]{40}$/, p.save)
    assert !Page.find("Hello", @repo).new?, 'Page.find("Hello", @repo).new? should be false'
    assert !Page.find("HowTo", @repo).new?, 'Page.find("HowTo", @repo).new? should be false'
  end

  should "supports nested pages" do
    p = Page.find("Hello/World", @repo)
    assert p.new?, 'p.new? should be true'
    assert_equal "Hello/World.markdown", p.name
    p.content = "foo"
    p.user = users(:johan)
    assert_match(/^[a-z0-9]{40}$/, p.save)

    p2 = Page.find("Hello/World", @repo)
    assert !p2.new?, 'p2.new? should be false'
  end

  should "has a basename without the extension" do
    p = Page.find("HowTo", @repo)
    assert_equal "HowTo", p.title

    assert_equal p.title, p.to_param
  end

  should 'alias id to to_param' do
    p = Page.find('HowTo', @repo)
    assert_equal(p.to_param, p.id)
  end

  should " have a commit" do
    p = Page.find("HowTo", @repo)
    assert_instance_of Grit::Commit, p.commit
    assert_equal "johan@johansorensen.com", p.commit.committer.email
    assert_equal "first commit", p.commit.message

    p2 = Page.find("somethingnew", @repo)
    assert p2.new?, 'p2.new? should be true'
    assert_equal nil, p2.commit
  end

  should " have a committed by user" do
    p = Page.find("HowTo", @repo)
    assert_equal users(:johan), p.committed_by_user
  end

  should " have the commit history of a page" do
    p = Page.find("HowTo", @repo)
    p.content = "something else"
    p.user = users(:johan); p.save

    assert_equal 2, p.history.size
    assert_equal "Updated HowTo", p.history.first.message
    assert_equal "first commit", p.history.last.message
  end

  should " validate the name of the page" do
    p = Page.find("kernel#wtf", @repo)
    p.user = users(:johan)
    assert !p.valid?, 'p.valid? should be false'
    assert !p.save, 'p.save should be false'

    assert Page.find("Kernel", @repo).valid?, 'Page.find("Kernel", @repo).valid? should be true'
    assert Page.find("KernelWhat", @repo).valid?, 'Page.find("KernelWhat", @repo).valid? should be true'
    assert Page.find("KernelWhatTheFsck", @repo).valid?, 'Page.find("KernelWhatTheFsck", @repo).valid? should be true'
  end

  def delete_test_repo
    FileUtils.rm_rf(@path) if File.exist?(@path)
  end

end
