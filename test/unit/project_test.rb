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


require File.dirname(__FILE__) + '/../test_helper'

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

  should_belong_to :containing_site
  should_have_many :merge_request_statuses

  should "have a title to be valid" do
    project = create_project(:title => nil)
    assert !project.valid?, 'valid? should be false'
    project.title = "foo"
    assert project.valid?
  end

  should "have a slug to be valid" do
    project = create_project(:slug => nil)
    assert !project.valid?, 'valid? should be false'
  end

  should "have a unique slug to be valid" do
    p1 = create_project
    p1.save!
    p2 = create_project(:slug => "FOO")
    assert !p2.valid?, 'valid? should be false'
    assert_not_nil p2.errors.on(:slug)
  end

  should "have an alphanumeric slug" do
    project = create_project(:slug => "asd asd")
    project.valid?
    assert !project.valid?, 'valid? should be false'
  end

  should "downcase the slug before validation" do
    project = create_project(:slug => "FOO")
    project.valid?
    assert_equal "foo", project.slug
  end

  should "cannot have a reserved name as slug" do
    project = create_project(:slug => Gitorious::Reservations.project_names.first)
    project.valid?
    assert_not_nil project.errors.on(:slug)

    project = create_project(:slug => "dashboard")
    project.valid?
    assert_not_nil project.errors.on(:slug)
  end

  should "creates the wiki repository on create" do
    project = create_project(:slug => "my-new-project")
    project.save!
    assert_instance_of Repository, project.wiki_repository
    assert_equal "my-new-project#{Repository::WIKI_NAME_SUFFIX}", project.wiki_repository.name
    assert_equal Repository::KIND_WIKI, project.wiki_repository.kind
    assert !project.repositories.include?(project.wiki_repository)
    assert_equal project.owner, project.wiki_repository.owner
  end

  should "finds a project by slug or raises" do
    assert_equal projects(:johans), Project.find_by_slug!(projects(:johans).slug)
    assert_raises(ActiveRecord::RecordNotFound) do
      Project.find_by_slug!("asdasdasd")
    end
  end

  should "has the slug as its params" do
    assert_equal projects(:johans).slug, projects(:johans).to_param
  end

  should "knows if a user is a admin on a project" do
    project = projects(:johans)
    assert project.admin?(users(:johan))
    project.owner = groups(:team_thunderbird)
    assert !project.admin?(users(:johan))
    project.owner.add_member(users(:johan), Role.admin)
    assert project.admin?(users(:johan))

    assert !project.admin?(users(:moe))
    project.owner.add_member(users(:moe), Role.member)
    assert !project.admin?(users(:moe))
    # be able to deal with AuthenticatedSystem's quirky design:
    assert !project.admin?(:false)
    assert !project.admin?(false)
    assert !project.admin?(nil)
  end

  should "knows if a user is a member on a project" do
    project = projects(:johans)
    assert project.member?(users(:johan))
    project.owner = groups(:team_thunderbird)
    assert !project.member?(users(:johan))
    project.owner.add_member(users(:johan), Role.member)
    assert project.member?(users(:johan))

    assert !project.member?(users(:moe))
    project.owner.add_member(users(:moe), Role.member)
    assert !project.admin?(users(:moe))
    # be able to deal with AuthenticatedSystem's quirky design:
    assert !project.member?(:false)
    assert !project.member?(false)
    assert !project.member?(nil)
  end

  should "knows if a user can delete the project" do
    project = projects(:johans)
    assert !project.can_be_deleted_by?(users(:moe))
    assert !project.can_be_deleted_by?(users(:johan)) # it has clones..
    project.repositories.clones.each(&:destroy)
    assert project.reload.can_be_deleted_by?(users(:johan)) # the clones are clone
  end

  should "strip html tags" do
    project = create_project(:description => "<h1>Project A</h1>\n<b>Project A</b> is a....")
    assert_equal "Project A\nProject A is a....", project.stripped_description
  end

  should "have a breadcrumb_parent method which returns nil" do
    project = create_project
    assert project.breadcrumb_parent.nil?
  end

  # should "strip html tags, except highlights" do
  #   project = create_project(:description => %Q{<h1>Project A</h1>\n<strong class="highlight">Project A</strong> is a....})
  #   assert_equal %Q(Project A\n<strong class="highlight">Project A</strong> is a....), #   project.stripped_description
  # end

  should "have valid urls ( prepending http:// if needed )" do
    project = projects(:johans)
    [ :home_url, :mailinglist_url, :bugtracker_url ].each do |attr|
      assert project.valid?
      project.send("#{attr}=", 'http://blah.com')
      assert project.valid?
      project.send("#{attr}=", 'ftp://blah.com')
      assert !project.valid?, 'valid? should be false'
      project.send("#{attr}=", 'blah.com')
      assert project.valid?
      assert_equal 'http://blah.com', project.send(attr)
    end
  end

  should "remove leading and trailing whitespace from the URL" do
    p = projects(:johans)
    assert_equal("http://foo.com/", p.clean_url(" http://foo.com/ "))
  end

  should "not prepend http:// to empty urls" do
    project = projects(:johans)
    [ :home_url, :mailinglist_url, :bugtracker_url ].each do |attr|
      project.send("#{attr}=", '')
      assert project.send(attr).blank?
      project.send("#{attr}=", nil)
      assert project.send(attr).blank?
    end
  end

  should "not allow invalid urls" do
    project = projects(:johans)

    project.home_url = "invalid@stuff"
    project.mailinglist_url = "invalid@mailinglist"
    project.bugtracker_url = "invalid@bugtracker"

    assert !project.valid?
    assert project.errors.on(:home_url)
    assert project.errors.on(:mailinglist_url)
    assert project.errors.on(:bugtracker_url)
  end

  should "allow valid urls" do
    project = projects(:johans)

    project.home_url = "http://home.com"
    project.mailinglist_url = "http://mailinglist.com"
    project.bugtracker_url = "http://bugtracker.com"

    assert project.valid?
    assert project.errors.on(:home_url).nil?
    assert project.errors.on(:mailinglist_url).nil?
    assert project.errors.on(:bugtracker_url).nil?
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
    assert !project.repositories.include?(repositories(:johans_wiki))
  end

  should "has to_param_with_prefix" do
    assert_equal projects(:johans).to_param, projects(:johans).to_param_with_prefix
  end

  should "change the owner of the wiki repo as well" do
    project = projects(:johans)
    project.change_owner_to(groups(:team_thunderbird))
    assert_equal groups(:team_thunderbird), project.owner
    assert_equal groups(:team_thunderbird), project.wiki_repository.owner
  end

  should "allow changing ownership from a user to a group, but not the other way around" do
    p = projects(:johans)
    p.change_owner_to(groups(:team_thunderbird))
    assert_equal groups(:team_thunderbird), p.owner
    p.change_owner_to(users(:johan))
    assert_equal groups(:team_thunderbird), p.owner
  end

  should "add group as admin to mainline repositories when changing ownership" do
    p = projects(:johans)
    assert_difference("Committership.count") { p.change_owner_to(groups(:team_thunderbird)) }
    committership = p.repositories.mainlines.first.committerships.detect { |c|
      c.committer == groups(:team_thunderbird)
    }
    assert_not_nil committership
    assert_equal(
      Committership::CAN_REVIEW | Committership::CAN_COMMIT | Committership::CAN_ADMIN,
      committership.permissions)
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

    should 'allow optional creation of events' do
      assert @project.new_event_required?(Action::UPDATE_WIKI_PAGE, @repository, @user, 'HomePage')
      event = @project.create_event(Action::UPDATE_WIKI_PAGE, @repository, @user, 'HomePage', Time.now)
      assert !@project.new_event_required?(Action::UPDATE_WIKI_PAGE, @repository, @user, 'HomePage')
      event.update_attributes(:created_at => 2.hours.ago)
      assert @project.new_event_required?(Action::UPDATE_WIKI_PAGE, @repository, @user, 'HomePage')
    end

    should "create an event even without a valid id" do
      assert_not_equal nil, @project.create_event(52342, @repository, @user)
    end

    should "creates valid attributes on the event" do
      e = @project.create_event(Action::COMMIT, @repository, @user, "somedata", "a body")
      assert e.valid?
      assert !e.new_record?, 'e.new_record? should be false'
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

  context "Thottling" do
    setup{ Project.destroy_all }

    should "throttle on create" do
      assert_nothing_raised do
        5.times{|i| create_project(:slug => "wifebeater#{i}").save! }
      end

      assert_no_difference("Project.count") do
        assert_raises(RecordThrottling::LimitReachedError) do
          create_project(:slug => "wtf-are-you-doing-bro").save!
        end
      end
    end
  end

  context 'Oauth' do
    setup do
      @project = projects(:johans)
      @project.oauth_signoff_site = 'http://oauth.example'
    end

    should 'return oauth_consumer_options with default paths' do
      assert_equal({:site => @project.oauth_signoff_site}, @project.oauth_consumer_options)
    end

    should 'append correct paths when a prefix is supplied' do
      @project.oauth_path_prefix = "/path/to/oauth"
      consumer_options = @project.oauth_consumer_options
      assert_equal('/path/to/oauth/request_token', consumer_options[:request_token_path])
    end

    should 'append a correct path even with strange options' do
      @project.oauth_path_prefix = "path/to/oauth/"
      consumer_options = @project.oauth_consumer_options
      assert_equal('/path/to/oauth/request_token', consumer_options[:request_token_path])
    end

    should 'be able to set the oauth options from a hash' do
      new_settings = {
        :path_prefix    => '/foo',
        :signoff_key    => 'kee',
        :site           => 'http://oauth.example.com',
        :signoff_secret => 'secret'
      }
      @project.oauth_settings = new_settings
      expected = {
          :site                 => 'http://oauth.example.com',
          :request_token_path   => '/foo/request_token',
          :authorize_path       => '/foo/authorize',
          :access_token_path    => '/foo/access_token'
        }
      assert @project.merge_requests_need_signoff?
      assert_equal expected, @project.oauth_consumer_options
      assert_equal 'kee', @project.oauth_signoff_key
      assert_equal 'secret', @project.oauth_signoff_secret
      assert_equal new_settings, @project.oauth_settings
    end

    should 'deactivate signoff on merge requests when passing an empty :site option in oauth_settings' do
      @project.oauth_settings = {:site => ''}
      assert !@project.merge_requests_need_signoff?
      @project.oauth_settings = {}
      assert !@project.merge_requests_need_signoff?
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

  context 'Merge request status tags' do
    setup {@project = Factory.create(:user_project)}

    should 'serialize merge_request_state_options' do
      @project.merge_request_custom_states = %w(Merged Verifying)
      assert_equal %w(Merged Verifying), @project.merge_request_custom_states
    end

    should 'be serializible through a text-only version' do
      assert_equal "Open\nClosed\nVerifying", @project.merge_request_states
      @project.merge_request_states = "Foo\nBar"
      assert_equal ['Foo','Bar'], @project.merge_request_custom_states
    end
  end

  should "create default merge_request_statuses on creation" do
    project = Factory.build(:user_project)
    assert project.new_record?
    project.save!

    assert_equal 2, project.reload.merge_request_statuses.count
    open_status, closed_status = project.merge_request_statuses
    assert_equal MergeRequest::STATUS_OPEN, open_status.state
    assert_equal "Open", open_status.name
    assert_equal MergeRequest::STATUS_CLOSED, closed_status.state
    assert_equal "Closed", closed_status.name
  end


  context "Searching" do
    setup do
      @owner = Factory.create(:user, :login => "thejoker")
      @project = Factory.create(:project, :user => @owner,
        :owner => @owner)
      @repo = Factory.create(:repository, :project => @project, :owner => @owner,
        :user => @owner, :name => "thework", :description => "halloween")
      @group = Factory.create(:group, :creator => @owner,
        :name => "foo-hackers", :user_id => @owner.to_param)
      @group_repo = Factory.create(:repository, :project => @project,
        :owner => @group, :name => "group-repo", :user => @owner)
      @tracking_repo = @repo.create_tracking_repository
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
      assert !@project.search_repositories("track").include?(@tracking_repo)
    end
  end

  context "Cloneable repositories" do
    setup do
      @owner = Factory.create(:user, :login => "thejoker")
      @project = Factory.create(:project, :user => @owner,
        :owner => @owner)
      @repo = Factory.create(:repository, :project => @project, :owner => @owner,
        :user => @owner, :name => "thework", :description => "halloween")
      @group = Factory.create(:group, :creator => @owner,
        :name => "foo-hackers", :user_id => @owner.to_param)
      @group_repo = Factory.create(:repository, :project => @project,
        :owner => @group, :name => "group-repo", :user => @owner)
      @tracking_repo = @repo.create_tracking_repository
    end

    should "include regular repositories" do
      assert @project.cloneable_repositories.include?(@group_repo)
      assert @project.cloneable_repositories.include?(@repo)
    end

    should "not include tracking repositories" do
      assert !@project.cloneable_repositories.include?(@tracking_repo)
    end

    should "include wiki repositories" do
      wiki = @project.wiki_repository
      assert_not_nil wiki
      assert @project.cloneable_repositories.include?(wiki)
    end
  end

  should "be added to the creators favorites" do
    p = create_project
    p.save!
    assert p.watched_by?(p.user)
  end

  context "Suspended projects" do
    setup do
      @project = projects(:johans)
    end

    should "by default not be suspended" do
      assert !@project.suspended?
    end

    should "be suspendable" do
      @project.suspend!
      assert @project.suspended? 
    end

    should "by default scope to non-suspended projects" do
      @project.suspend!
      @project.save!
      assert !Project.all.include?(@project)
    end
  end

  context "Tagging" do
    setup do
      @project = Factory.create(:user_project)
    end

    should "have a tag_list= setter" do
      @project.tag_list = "fun pretty scary"
      assert_equal(%w(fun pretty scary), @project.tag_list)
    end    
  end

  should "not allow api as slug" do
    p = Project.new(:slug => "api")
    assert !p.valid?
    assert_not_nil p.errors.on(:slug)
  end
end
