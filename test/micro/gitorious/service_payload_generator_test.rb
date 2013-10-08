# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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
require "fast_test_helper"
require "grit"
require "push_spec_parser"
require "gitorious/service_payload_generator"

class ServicePayloadGeneratorTest < MiniTest::Spec
  before do
    @repository = Repository.new
    @repository.project = Project.new(:slug => "my-project", :description => "Yes, mine")
    @repository.clones = [{}]
    @repository.browse_url = "http://gitorious.test/my-project/name"
    @repository.full_repository_path = (Rails.root + "test/fixtures/push_test_repo.git").to_s

    @start_sha = "ec433174463a9d0dd32700ffa5bbb35cfe2a4530"
    @end_sha = "7b5fe553c3c37ffc8b4b7f8c27272a28a39b640f"
    grit = mock
    grit.stubs(:commits_between).with(@start_sha, @end_sha).returns([grit_commit])
    @repository.stubs(:git).returns(grit)

    @spec = PushSpecParser.new(@start_sha, @end_sha, "refs/heads/master")
    @user = @repository.owner = User.new(:login => "johan")

    @generator = Gitorious::ServicePayloadGenerator.new(@repository, @spec, @user)
  end

  describe "Generating payload" do
    it "contains the start sha" do
      payload = @generator.payload
      assert_equal @start_sha, payload[:before]
    end

    it "contains the end sha" do
      payload = @generator.payload
      assert_equal @end_sha, payload[:after]
    end

    it "contains the username of the pusher" do
      payload = @generator.payload
      assert_equal @user.login, payload[:pushed_by]
    end

    it "contains the ref pushed to" do
      payload = @generator.payload
      assert_equal "master", payload[:ref]
    end

    it "contains the pushed_at in XML schema" do
      payload = @generator.payload
      assert_equal @repository.last_pushed_at.xmlschema, payload[:pushed_at]
    end

    it "contains project name and description" do
      project = @repository.project
      project.update_attribute(:slug, "my-project")
      project.update_attribute(:description, "Yes, mine")
      payload = @generator.payload

      assert_equal "my-project", payload[:project][:name]
      assert_equal "Yes, mine", payload[:project][:description]
    end

    it "contains repository information" do
      @repository.name = "name"
      @repository.description = "Terrible hacks"
      payload = @generator.payload

      assert_equal Gitorious.url("/#{@repository.project.slug}/#{@repository.name}"), payload[:repository][:url]
      assert_equal "name", payload[:repository][:name]
      assert_equal "Terrible hacks", payload[:repository][:description]
      assert_equal 1, payload[:repository][:clones]

      assert_equal({ :name => "johan" }, payload[:repository][:owner])
    end
  end

  describe "commits" do
    it "gets commits between start and end sha" do
      @generator.fetch_commits
    end

    it "returns list of commit details" do
      commits = @generator.fetch_commits

      assert_equal 1, commits.count
      commit = commits.first

      assert_equal "jane@g.org", commit[:author][:email]
      assert_equal "Jane Author", commit[:author][:name]
      assert_equal 2.days.ago.xmlschema, commit[:committed_at]
      assert_equal SHA, commit[:id]
      assert_equal "Awesome sauce", commit[:message]
      assert_equal 1.day.ago.xmlschema, commit[:timestamp]
      assert_equal "#{@repository.browse_url}/commit/#{SHA}", commit[:url]
    end

    it "contains a list of commits" do
      payload = @generator.payload

      assert_kind_of Array, payload[:commits]
    end
  end

  def grit_commit
    committer = Grit::Actor.new("John Committer", "noone@invalid.org")
    author = Grit::Actor.new("Jane Author", "jane@g.org")
    grit_commit = Grit::Commit.new(nil, SHA, [], nil,
      author, 1.day.ago,
      committer, 2.days.ago,
      ["Awesome sauce"])
  end
end
