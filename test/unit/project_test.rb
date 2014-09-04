# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class ProjectTest < ActiveSupport::TestCase
  def create_project(options={})
    Project.new({
        :title => "foo project",
        :slug => "foo",
        :description => "my little project",
        :user => users(:johan),
        :owner => users(:johan)
      }.merge(options))
  end

  should belong_to(:containing_site)
  should have_many(:merge_request_statuses)

  should "downcase slug" do
    project = create_project(:slug => "FOO")
    assert_equal "foo", project.slug
  end

  should "recognize unique project" do
    project = Project.first
    assert project.uniq?

    project.save!
    assert project.uniq?

    project2 = create_project(:slug => project.slug.upcase)
    refute project2.uniq?
  end

  should "use slug as param representation" do
    assert_equal projects(:johans).slug, projects(:johans).to_param
  end

  should "have to_param_with_prefix" do
    assert_equal projects(:johans).to_param, projects(:johans).to_param_with_prefix
  end

  should "know if a user is admin on a project" do
    project = projects(:johans)
    assert admin?(users(:johan), project)

    project.owner = groups(:team_thunderbird)
    refute admin?(users(:johan), project)

    project.owner.add_member(users(:johan), Role.admin)
    assert admin?(users(:johan), project)
    refute admin?(users(:moe), project)

    project.owner.add_member(users(:moe), Role.member)
    refute admin?(users(:moe), project)

    refute admin?(false, project)
    refute admin?(nil, project)
  end

  should "know if a user is a member on a project" do
    project = projects(:johans)
    assert project.member?(users(:johan))

    project.owner = groups(:team_thunderbird)
    refute project.member?(users(:johan))

    project.owner.add_member(users(:johan), Role.member)
    assert project.member?(users(:johan))

    refute project.member?(users(:moe))

    project.owner.add_member(users(:moe), Role.member)
    refute admin?(users(:moe), project)

    refute project.member?(false)
    refute project.member?(nil)
  end

  should "know if a user can delete the project" do
    project = projects(:johans)
    refute can_delete?(users(:moe), project)
    refute can_delete?(users(:johan), project) # it has clones..

    project.repositories.clones.each(&:destroy)
    assert can_delete?(users(:johan), project.reload) # the clones are gone
  end

  should "strip html tag" do
    project = create_project(:description => "<h1>Project A</h1>\n<b>Project A</b> is a....")
    assert_equal "Project A\nProject A is a....", project.stripped_description
  end

  should "remove leading and trailing whitespace from the URL" do
    p = projects(:johans)
    p.home_url = " http://foo.com/ "

    assert_equal "http://foo.com/", p.home_url
  end

  should "prepend http:// to URLs" do
    project = projects(:johans)

    [:home_url, :mailinglist_url, :bugtracker_url].each do |attr|
      project.send("#{attr}=", "url.com")
      assert_equal "http://url.com", project.send(attr)
    end
  end

  should "not prepend http:// to empty URLs" do
    project = projects(:johans)
    [ :home_url, :mailinglist_url, :bugtracker_url ].each do |attr|
      project.send("#{attr}=", "")
      assert project.send(attr).blank?
      project.send("#{attr}=", nil)
      assert project.send(attr).blank?
    end
  end

  should "find or create an associated wiki repo" do
    project = projects(:johans)
    repo = repositories(:johans)
    repo.kind = Repository::KIND_WIKI
    project.wiki_repository = repo
    project.save!
    assert_equal repo, project.reload.wiki_repository
  end

  should "have a wiki repository" do
    project = projects(:johans)
    assert_equal repositories(:johans_wiki), project.wiki_repository
    refute project.repositories.include?(repositories(:johans_wiki))
  end

  should "consider LdapGroup owned projects group owned" do
    project = projects(:johans)
    project.owner = ldap_groups(:first_ldap_group)
    assert project.owned_by_group?
  end

  should "transfer ownership to an LDAP group" do
    new_owner = ldap_groups(:first_ldap_group)
    project = projects(:johans)
    repo = project.repositories.first
    c = repo.committerships.create!(:committer => new_owner,:creator_id => new_owner.id)
    c.build_permissions(:review, :commit, :admin)
    c.save!
  end

  should "delegate wiki permissions to the wiki repository" do
    project = projects(:johans)
    assert_equal project.wiki_repository.wiki_permissions, project.wiki_permissions
    project.wiki_permissions = 2
    assert_equal 2, project.wiki_permissions
  end

  should "extract first paragraph from description" do
    project = projects(:johans)

    project.description = "Hello.\nWorld."
    assert_equal "Hello.", project.descriptions_first_paragraph

    project.description = "No newline."
    assert_equal "No newline.", project.descriptions_first_paragraph
  end

  context "Project events" do
    setup do
      @project = projects(:johans)
      @user = users(:johan)
      @repository = repositories(:johans)
    end

    should "create an event from the action name" do
      assert_not_equal nil, @project.create_event(Action::CREATE_PROJECT, @repository, @user, "", "")
    end

    should "allow optional creation of events" do
      assert @project.new_event_required?(Action::UPDATE_WIKI_PAGE, @repository, @user, 'HomePage')
      event = @project.create_event(Action::UPDATE_WIKI_PAGE, @repository, @user, 'HomePage', Time.now)
      refute @project.new_event_required?(Action::UPDATE_WIKI_PAGE, @repository, @user, 'HomePage')
      event.update_attributes(:created_at => 2.hours.ago)
      assert @project.new_event_required?(Action::UPDATE_WIKI_PAGE, @repository, @user, 'HomePage')
    end

    should "create an event even without a valid id" do
      assert_not_equal nil, @project.create_event(52342, @repository, @user)
    end

    should "create valid attributes on the event" do
      e = @project.create_event(Action::COMMIT, @repository, @user, "somedata", "a body")
      assert e.valid?
      refute e.new_record?, 'e.new_record? should be false'
      e.reload
      assert_equal Action::COMMIT, e.action
      assert_equal @repository, e.target
      assert_equal @project, e.project
      assert_equal @user, e.user
      assert_equal "somedata", e.data
      assert_equal "a body", e.body
    end
  end

  context "Containing Site" do
    should "have a site" do
      assert_equal sites(:qt), projects(:thunderbird).site
    end

    should "have a default site if site_id is nil" do
      assert_equal Site.default.title, projects(:johans).site.title
    end
  end

  context "Oauth" do
    setup do
      @project = projects(:johans)
      @project.oauth_signoff_site = "http://oauth.example"
    end

    should "return oauth_consumer_options with default paths" do
      assert_equal({:site => @project.oauth_signoff_site}, @project.oauth_consumer_options)
    end

    should "append correct paths when a prefix is supplied" do
      @project.oauth_path_prefix = "/path/to/oauth"
      consumer_options = @project.oauth_consumer_options
      assert_equal("/path/to/oauth/request_token", consumer_options[:request_token_path])
    end

    should "append a correct path even with strange options" do
      @project.oauth_path_prefix = "path/to/oauth/"
      consumer_options = @project.oauth_consumer_options
      assert_equal("/path/to/oauth/request_token", consumer_options[:request_token_path])
    end

    should "be able to set the oauth options from a hash" do
      new_settings = {
        :path_prefix    => "/foo",
        :signoff_key    => "kee",
        :site           => "http://oauth.example.com",
        :signoff_secret => "secret"
      }
      @project.oauth_settings = new_settings
      expected = {
        :site                 => "http://oauth.example.com",
        :request_token_path   => "/foo/request_token",
        :authorize_path       => "/foo/authorize",
        :access_token_path    => "/foo/access_token"
      }
      assert @project.merge_requests_need_signoff?
      assert_equal expected, @project.oauth_consumer_options
      assert_equal "kee", @project.oauth_signoff_key
      assert_equal "secret", @project.oauth_signoff_secret
      assert_equal new_settings, @project.oauth_settings
    end

    should "deactivate signoff on merge requests when passing an empty :site option in oauth_settings" do
      @project.oauth_settings = {:site => ""}
      refute @project.merge_requests_need_signoff?
      @project.oauth_settings = {}
      refute @project.merge_requests_need_signoff?
    end
  end

  context "#to_xml" do
    setup do
      @project = projects(:johans)
    end

    should "not include oauth keys" do
      assert_no_match(/<oauth/, @project.to_xml)
      assert_no_match(/<merge-requests-need-signoff/, @project.to_xml)
    end

    should "include a list of the mainline repositories" do
      assert_match(/<mainlines/, @project.to_xml)
    end

    should "include a list of the repository clones" do
      assert_match(/<clones/, @project.to_xml)
    end
  end

  context "Merge request status tags" do
    setup { @project = FactoryGirl.create(:user_project) }

    should "serialize merge_request_state_options" do
      @project.merge_request_custom_states = %w(Merged Verifying)
      assert_equal %w(Merged Verifying), @project.merge_request_custom_states
    end

    should "be serializible through a text-only version" do
      assert_equal "Open\nClosed\nVerifying", @project.merge_request_states
      @project.merge_request_states = "Foo\nBar"
      assert_equal ["Foo","Bar"], @project.merge_request_custom_states
    end

    should "allow mass assignment" do
      statuses = @project.merge_request_statuses.inject({}) do |h, mrs|
        h[h.length.to_s] = { "id" => mrs.id, "state" => mrs.state, "_destroy" => "",
          "name" => mrs.name, "description" => mrs.description, "color" => mrs.color }
        h
      end
      statuses["1361955144388"] = { "state" => "5", "name" => "Newz", "description" => "", "color" => "" }
      @project.attributes = { "merge_request_statuses_attributes" => statuses }
      @project.save

      assert_equal @project.reload.merge_request_statuses.last.name, "Newz"
    end
  end

  context "Searching" do
    setup do
      @owner = FactoryGirl.create(:user, :login => "thejoker")
      @project = FactoryGirl.create(:project, :user => @owner,
        :owner => @owner)
      @repo = FactoryGirl.create(:repository, :project => @project, :owner => @owner,
        :user => @owner, :name => "thework", :description => "halloween")
      @group = FactoryGirl.create(:group, :creator => @owner,
        :name => "foo-hackers", :user_id => @owner.to_param)
      @group_repo = FactoryGirl.create(:repository, :project => @project,
        :owner => @group, :name => "group-repo", :user => @owner)
      command = CreateTrackingRepositoryCommand.new(Gitorious::App, @repo)
      @tracking_repo = command.execute(command.build)
    end

    should "find repositories matching the repo name" do
      assert @project.search_repositories("work").include?(@repo)
    end

    should "find repositories with a matching description" do
      assert @project.search_repositories("ween").include?(@repo)
    end

    should "find repositories matching the owning user's name" do
      assert @project.search_repositories("joker").include?(@repo)
    end

    should "find repositories matching the owning group's name" do
      assert @project.search_repositories("hackers").include?(@group_repo)
    end

    should "only include regular repositories" do
      refute @project.search_repositories("track").include?(@tracking_repo)
    end
  end

  context "Cloneable repositories" do
    setup do
      @owner = FactoryGirl.create(:user, :login => "thejoker")
      @project = FactoryGirl.create(:project, :user => @owner,
        :owner => @owner)
      @repo = FactoryGirl.create(:repository, :project => @project, :owner => @owner,
        :user => @owner, :name => "thework", :description => "halloween")
      @group = FactoryGirl.create(:group, :creator => @owner,
        :name => "foo-hackers", :user_id => @owner.to_param)
      @group_repo = FactoryGirl.create(:repository, :project => @project,
        :owner => @group, :name => "group-repo", :user => @owner)
      command = CreateTrackingRepositoryCommand.new(Gitorious::App, @repo)
      @tracking_repo = command.execute(command.build)
    end

    should "include regular repositories" do
      assert @project.cloneable_repositories.include?(@group_repo)
      assert @project.cloneable_repositories.include?(@repo)
    end

    should "not include tracking repositories" do
      refute @project.cloneable_repositories.include?(@tracking_repo)
    end

    should "include wiki repositories" do
      cmd = CreateWikiRepositoryCommand.new(MessageHub.new)
      cmd.execute(cmd.build(@project))

      wiki = @project.wiki_repository
      assert_not_nil wiki
      assert @project.cloneable_repositories.include?(wiki)
    end
  end

  context "#members" do
    should "return uniq members of all mainlines" do
      project = projects(:johans)
      user = users(:johan)

      assert_equal [user], project.members
    end
  end

  context "Suspended projects" do
    setup do
      @project = projects(:johans)
    end

    should "by default not be suspended" do
      refute @project.suspended?
    end

    should "be suspendable" do
      @project.suspend!
      assert @project.suspended?
    end

    should "by default scope to non-suspended projects" do
      @project.suspend!
      @project.save!
      refute Project.all.include?(@project)
    end
  end

  context "Tagging" do
    setup do
      @project = FactoryGirl.create(:user_project)
    end

    should "have a tag_list= setter" do
      @project.tag_list = "fun pretty scary"
      assert_equal(%w(fun pretty scary), @project.tag_list)
    end
  end

  context "Database authorization" do
    context "with private repositories enabled" do
      setup do
        @settings = Gitorious::Configuration.prepend("enable_private_repositories" => true)
      end

      teardown do
        Gitorious::Configuration.prune(@settings)
      end

      should "allow anonymous user to view public project" do
        project = Project.new(:title => "My project")
        assert can_read?(nil, project)
      end

      should "allow owner to view private project" do
        projects(:johans).owner = users(:johan)
        projects(:johans).add_member(users(:johan))
        assert can_read?(users(:johan), projects(:johans))
      end

      should "disallow anonymous user to view private project" do
        projects(:johans).add_member(users(:johan))
        refute can_read?(nil, projects(:johans))
      end

      should "allow member to view private project" do
        projects(:johans).owner = users(:johan)
        projects(:johans).add_member(users(:mike))
        assert can_read?(users(:mike), projects(:johans))
      end

      should "allow member to view private project via group membership" do
        projects(:johans).owner = users(:johan)
        projects(:johans).add_member(groups(:team_thunderbird))
        assert can_read?(users(:mike), projects(:johans))
      end
    end

    context "with private repositories disabled" do
      should "allow anonymous user to view 'private' project" do
        Gitorious::Configuration.override("enable_private_repositories" => false) do
          projects(:johans).add_member(users(:johan))
          assert can_read?(nil, projects(:johans))
        end
      end
    end

    context "making projects private" do
      should "add owner as member" do
        @user = users(:johan)
        @project = projects(:johans)
        Gitorious::Configuration.override("enable_private_repositories" => true) do
          @project.make_private
          refute can_read?(users(:mike), @project)
        end
      end
    end
  end

  context "project memberships" do
    should "silently ignore duplicates" do
      project = projects(:johans)
      project.add_member(users(:mike))
      project.add_member(users(:mike))

      assert project.member?(users(:mike))
      assert is_member?(users(:mike), project)
      assert_equal 1, project.content_memberships.count
    end
  end

  context "Housekeeping" do
    setup do
      @project = create_project(:slug => "cleanly")
      @project.save!
    end

    should "delete custom merge request states" do
      state = @project.merge_request_statuses.create!(
        :name => "gone",
        :state => MergeRequest::STATUS_CLOSED)
      assert_incremented_by(MergeRequestStatus, :count, -1) do
        @project.destroy
      end
    end
  end

  should "count open merge requests" do
    assert_equal 2, projects(:johans).merge_requests.open.count
  end

  private
  def create_event(project, target, user)
    e = Event.new({ :target => target,
        :data => "master",
        :action => Action::CREATE_BRANCH })
    e.user = user
    e.project = project
    e.save!
  end
end
