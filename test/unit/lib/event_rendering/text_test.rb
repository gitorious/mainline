# encoding: utf-8
#--
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


require File.dirname(__FILE__) + '/../../../test_helper'

class TextEventRenderingTest < ActiveSupport::TestCase
  def setup
    @event = Event.new({
        :target => repositories(:johans),
        :body => 'blabla',
        :project => repositories(:johans).project,
        :action => Action::PUSH,
        :user => users(:johan)
      })
  end

  context "in general" do
    should "Have a render(event) api" do
      assert EventRendering::Text.respond_to?(:render)

      render_mock = mock
      EventRendering::Text.expects(:new).with(@event).returns(render_mock)
      render_mock.expects(:render)

      EventRendering::Text.render(@event)
    end

    should "always include a project link" do
      res = render(@event)
      assert_match /\nhttp:\/\/gitorious\.test\/johans-project$/, res
    end

    should "raise error for unknown actions" do
      @event.action = 666
      assert_raises(EventRendering::UnknownActionError) do
        render(@event)
      end
    end
  end

  context "from a string template" do
    setup { @renderer = EventRendering::Text.new(@event) }

    should "replace a single key" do
      res = @renderer.template_to_str("foo {what} baz", :what => "bar")
      assert_equal "foo bar baz", res
    end

    should "replace multiple occurances" do
      res = @renderer.template_to_str("foo {what} {what}", :what => "bar")
      assert_equal "foo bar bar", res
    end

    should "replace multiple values" do
      res = @renderer.template_to_str("{a}-{b} {c}!", {
          :a => "foo",
          :b => "bar",
          :c => "baz"
        })
      assert_equal "foo-bar baz!", res
    end
  end

  context "clone repository event" do
    setup do
      @event.action = Action::CLONE_REPOSITORY
      @clone_repo = @event.target.clones.first
      assert_not_nil @clone_repo
      @event.target = @clone_repo
      @event.data = repositories(:johans).id
      @output = render(@event)
    end

    should "render the username who cloned it" do
      assert @output.include?("#{@clone_repo.user.login} cloned"), @output
    end

    should "include the name of the source repository" do
      assert_match /#{repositories(:johans).url_path}/, @output
    end

    should "render the url of the clone" do
      exp = " #{GitoriousConfig['scheme']}://#{GitoriousConfig['gitorious_host']}/#{@clone_repo.url_path}"
      assert @output.include?(exp), "did not include the url in: #{@output}"
    end
  end

  context "delete repo" do
    setup do
      @event.action = Action::DELETE_REPOSITORY
      @event.target = users(:johan)
      @event.data = "old-repo-name"
    end

    should "render a repo deletion event" do
      assert_match /^johan deleted repository old-repo-name/, render(@event)
    end
  end

  context "creating and deleting branches" do
    setup do
      @event.data = "branch-name"
    end

    should "render creation of branch" do
      @event.action = Action::CREATE_BRANCH
      res = render(@event)
      assert_match /^johan created branch branch-name in /, res
    end

    should "render deletion of branch" do
      @event.action = Action::DELETE_BRANCH
      res = render(@event)
      assert_match /^johan deleted branch branch-name in /, res
    end
  end

  context "Merge request updates" do
    setup do
      @event.target = merge_requests(:moes_to_johans)
    end

    should "render creation of merge request" do
      @event.action = Action::REQUEST_MERGE
      result = render(@event)
      assert_match /^johan requested a merge of johansprojectrepos-clone with johansprojectrepos/, result
    end

    should "include a link to the merge request on update" do
      @event.action = Action::UPDATE_MERGE_REQUEST
      result = render(@event)
      assert_no_match /johans-project$/, result
      assert_match /johans-project\/johansprojectrepos\/merge_requests\/#{@event.target.to_param}/, result
    end

    should "render deletion of merge requests" do
      @event.action = Action::DELETE_MERGE_REQUEST
      result = render(@event)
      assert_match /^johan deleted merge request for johansprojectrepos-clone with johansprojectrepos/, result
    end
  end
  
  context "creating and deleting tags" do
    setup do
      @event.data = "v1.0"
    end

    should "render creation of branch" do
      @event.action = Action::CREATE_TAG
      res = render(@event)
      assert_match /^johan created tag v1.0 in /, res
    end

    should "render deletion of branch" do
      @event.action = Action::DELETE_TAG
      res = render(@event)
      assert_match /^johan deleted tag v1.0 in /, res
    end

    should "include the tag message" do
      @event.action = Action::CREATE_TAG
      @event.body = "Tagged 1.0"
      res = render(@event)
      assert_match /Tagged 1\.0/, res
    end
  end

  context "Adding and removing collaborators" do
    setup do
      @event.data = "bob-the-user"
    end

    should "render creation of branch" do
      @event.action = Action::ADD_COMMITTER
      res = render(@event)
      assert_match /^johan added bob-the-user as collaborator to /, res
    end

    should "render deletion of branch" do
      @event.action = Action::REMOVE_COMMITTER
      res = render(@event)
      assert_match /^johan removed bob-the-user as collaborator from /, res
    end

    should "include the repo url" do
      @event.action = Action::ADD_COMMITTER
      res = render(@event)
      assert res.include?("gitorious.test/#{@event.target.url_path}"), "url not in: #{res}"
    end
  end

  context "a comment" do
    setup do
      @comment = Comment.last
      @comment.update_attribute(:sha1, "abc123")
      @event.action = Action::COMMENT
      @event.body = "MergeRequest"
      @event.data = @comment.id
      @merge_request = MergeRequest.last
      @event.target = @merge_request
    end

    should "render the user and comment body" do
      res = render(@event)
      assert_match(/^johan commented on/, res)
      assert res.include?(@comment.body), "comment body not in #{res.inspect}"
    end

    should "include a link back to the merge request" do
      res = render(@event)
      url = "/#{@merge_request.target_repository.url_path}/"
      url << "merge_requests/#{@merge_request.to_param}"
      assert res.include?("gitorious.test#{url}"), "#{url} not in: #{res}"
    end

    should "include a link back to the commit" do
      @event.target = repositories(:johans)
      @event.body = "Repository"
      url = "/#{@merge_request.target_repository.url_path}/commit/#{@comment.sha1}"
      res = render(@event)
      assert res.include?("gitorious.test#{url}"), "#{url} not in: #{res}"
    end
  end

  context "a push" do
    setup do
      @event.action = Action::PUSH
      @event.body = "master changed from abc213 to 123abc"
      @event.data = "master"
      @event.target = repositories(:johans)
    end

    should "include the ref change" do
      res = render(@event)
      assert res.include?("master changed from abc213 to 123abc")
    end

    should "include the number of commits pushed" do
      10.times do |i|
        @event.build_commit({
            :email  => 'John Schmidt <john{@example.com>',
            :data   => 'acb123#{i}',
            :body   => 'Added foo.#{i}'
          }).save!
      end
      assert_match("johan pushed 10 commits to master", render(@event))
    end

    should "include a list of the commits messages along with an url for each" do
      commit1 = @event.build_commit({:email => 'John Schmidt <john@example.com>',
          :data => 'acb123abc123', :body => 'Added foo'})
      commit2 = @event.build_commit({:email => 'Jane Schmidt <jane@example.com>',
          :data => '321abc321abc', :body => 'added bar'})
      [commit1, commit2].each(&:save)
      assert @event.reload.has_commits?

      res = render(@event)
      assert res.include?("John Schmidt committed acb123:\n"), "name not in #{res.inspect}"
      assert res.include?(commit1.body), "msg not in #{res}"
      assert res.include?("gitorious.test/#{@event.target.url_path}/commit/#{commit1.data}")

      assert res.include?("Jane Schmidt committed 321abc:\n"), "name not in #{res}"
      assert res.include?(commit2.body), "msg not in #{res}"
      assert res.include?("gitorious.test/#{@event.target.url_path}/commit/#{commit2.data}")
    end
  end

  context "A project" do
    setup { @event.target = projects(:johans) }

    context "creation" do
      setup { @event.action = Action::CREATE_PROJECT }

      should "include the creator and project name" do
        res = render(@event)
        assert_match(/^johan created project #{@event.target.title}/, res)
        assert res.include?(projects(:johans).description), "desc. not in #{res}"
      end

      should "include the project description" do
        res = render(@event)
        assert res.include?(projects(:johans).description), "desc. not in #{res}"
      end
    end

    context "updating" do
      setup { @event.action = Action::UPDATE_PROJECT }

      should "include the updator and project name" do
        assert_match(/^johan updated project #{projects(:johans).title}/, render(@event))
      end
    end
  end

  context "wiki page" do
    setup do
      @event.action = Action::UPDATE_WIKI_PAGE
      @event.data = "AWikiPage"
      @event.target = projects(:johans)
    end

    should "include the user and page name" do
      assert_match(/^johan updated wiki page AWikiPage/, render(@event))
    end

    should "include a link to the wiki page" do
      res = render(@event)
      url = "gitorious.test/#{@event.target.slug}/pages/AWikiPage"
      assert res.include?(url), "no link in: #{res}"
    end
  end

  context "Adding a project repo" do
    setup do
      @event.action = Action::ADD_PROJECT_REPOSITORY
      @event.target = repositories(:johans)
    end

    should "render the user and repo name" do
      assert_match(/^johan added a repository to #{@event.target.project.title}/,
        render(@event))
    end

    should "include a link to the repo" do
      res = render(@event)
      url = "gitorious.test/#{@event.target.url_path}"
      assert res.include?(url), "repo url not in: #{res}"
    end

    should "include the repo description, if present" do
      @event.target.update_attribute(:description, "moooooo")
      res = render(@event)
      assert res.include?(@event.target.description + "\n"), "repo descr. not in: #{res}"
    end
  end

  context "updating a repository" do
    setup do
      @event.action = Action::UPDATE_REPOSITORY
      @event.body = "Changed the repository description"
      @event.target = repositories(:johans)
    end

    should "render the username and repo name" do
      res = render(@event)
      assert_match(/^johan updated #{@event.target.url_path}/, res)
      assert res.include?(@event.body), "event body not in: #{res}"
    end
  end

  context "favoriting" do
    setup do
      @event.action = Action::ADD_FAVORITE
      @event.target = users(:mike)
      @repo = repositories(:johans)
      @event.body = @repo.class.name
      @event.data = @repo.id
    end

    should "include the username and watchable" do
      assert_match(/^johan favorited #{@repo.url_path}/, render(@event))
    end

    should "include a link to the watchable" do
      res = render(@event)
      url = "gitorious.test/#{@repo.url_path}"
      assert res.include?(url), "link not in: #{res}"
    end

    should "include the merge request sequence number" do
      mr = MergeRequest.last
      @event.body = mr.class.name
      @event.data = mr.id
      assert_match(/^johan favorited merge request ##{mr.sequence_number}/,
        render(@event))
    end
  end


  context "Push events, new style" do
    setup do
      @event.action = Action::PUSH_SUMMARY
      @repository = @event.target
      @project = @repository.project
      @first_sha = "a"*40
      @last_sha = "f"*40
      data = [@first_sha, @last_sha, "master", "10"].join(PushEventLogger::PUSH_EVENT_DATA_SEPARATOR)
      @event.data = data
      @event.target = repositories(:johans)
    end

    should "include the ref change" do
      res = render(@event)
      assert res.include?("master changed from #{@first_sha[0,7]} to #{@last_sha[0,7]}")
    end

    should "include the number of commits pushed" do
      assert_match("johan pushed 10 commits to master", render(@event))
    end

    should "a URL to the repository" do
      assert_match("/#{@project.slug}/#{@repository.name}/commits", render(@event))
    end
  end


  protected
  def render(event)
    ::EventRendering::Text.render(event)
  end
end
