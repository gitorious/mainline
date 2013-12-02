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

class EventsControllerTest < ActionController::TestCase
  def setup
    @project = projects(:johans)
    @repository = repositories(:johans)
  end

  def fake_commit
    grit_commit = stub(
      :id => "sha123",
      :committer => stub(:email => "foo@bar.com", :name => "Foo"),
      :committed_date => Time.now,
      :message => "initial commit")
    Gitorious::Commit.new(grit_commit)
  end

  context "commits" do
    setup do
      @push_event = create_push_event
    end

    should "show commits under a push event" do
      get :commits, :id => @push_event.to_param, :format => "js"
      assert_response :success
    end

    should "cache the commit events" do
      get :commits, :id => @push_event.to_param, :format => "js"
      assert_response :success
      assert_equal "max-age=1800, private", @response.headers["Cache-Control"]
    end
  end

  context "commits read from git, AKA new style push" do
    setup do
      @first_sha = "a"*40
      @last_sha = "f"*40
      event_data = [@first_sha, @last_sha, "master","10"].join(PushEventLogger::PUSH_EVENT_DATA_SEPARATOR)
      @push_event = @project.create_event(Action::PUSH_SUMMARY, @repository, User.first,
        event_data, "", 10.days.ago)
    end

    should "load commits from Gitorious::Commit" do
      @grit = mock
      Repository.any_instance.stubs(:git).returns(@grit)

      Gitorious::Commit.expects(:load_commits_between).with(@grit, @first_sha, @last_sha, @push_event.id).returns([fake_commit])

      get :commits, :id => @push_event.to_param, :format => "js"
      assert_response :success
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories(@project)
    end

    should "not show push event commits to unauthorized users" do
      get :commits, :id => create_push_event.to_param, :format => "js"
      assert_response 403
    end

    should "show push event commits to authorized users" do
      login_as :johan
      get :commits, :id => create_push_event.to_param, :format => "js"
      assert_response 200
    end
  end

  context "With private repositories" do
    setup do
      enable_private_repositories(@repository)
    end

    should "not show push event commits to unauthorized users" do
      get :commits, :id => create_push_event.to_param, :format => "js"
      assert_response 403
    end

    should "show push event commits to authorized users" do
      login_as :johan
      get :commits, :id => create_push_event.to_param, :format => "js"
      assert_response 200
    end
  end

  private
  def create_push_event
    push_event = @project.create_event(Action::PUSH, @repository, User.first,
                                        "", "A push event", 10.days.ago)
    10.times do |n|
      push_event.build_commit({ :email => "John Doe <john@doe.org>",
                                 :body => "Commit number #{n}",
                                 :data => "ffc0#{n}" }).save
    end
    push_event
  end
end
