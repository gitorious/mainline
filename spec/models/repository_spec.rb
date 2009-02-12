#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 David Aguilar <davvid@gmail.com>
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
require "ostruct"

describe Repository do
  before(:each) do
    @repository = new_repos
    FileUtils.mkdir_p(@repository.full_repository_path, :mode => 0755)
  end
  
  def new_repos(opts={})
    Repository.new({
      :name => "foo",
      :project => projects(:johans),
      :user => users(:johan),
      :owner => projects(:johans)
    }.merge(opts))
  end
  
  it "should have valid associations" do
    @repository.should have_valid_associations
  end

  it "should have a name to be valid" do
    @repository.name = nil
    @repository.should_not be_valid
  end
  
  it "should only accept names with alphanum characters in it" do
    @repository.name = "foo bar"
    @repository.should_not be_valid
    
    @repository.name = "foo!bar"
    @repository.should_not be_valid
    
    @repository.name = "foobar"
    @repository.should be_valid
    
    @repository.name = "foo42"
    @repository.should be_valid
  end
  
  it "has a unique name within a project" do
    @repository.save
    repos = new_repos(:name => "FOO")
    repos.should_not be_valid
    repos.should have(1).error_on(:name)
    
    new_repos(:project => projects(:moes)).should be_valid
  end
  
  it "cannot have a reserved name" do
    repo = new_repos(:name => Gitorious::Reservations::REPOSITORY_NAMES.first)
    repo.valid?
    repo.errors_on(:name).should_not be_blank
  end
  
  it "sets itself as mainline if the owner is Project" do
    @repository.project = nil
    @repository.owner = projects(:johans)
    @repository.save
    @repository.mainline?.should == true
    @repository.project.should == projects(:johans)
  end
  
  it "doesn't set itself as mainline if the owner is a Group" do
    @repository.owner = groups(:team_thunderbird)
    @repository.save
    @repository.mainline?.should == false
  end
  
  it "doesn't set itself as mainline if the owner is a User" do
    @repository.owner = users(:johan)
    @repository.save
    @repository.mainline?.should == false
  end
  
  it "has a gitdir name" do
    @repository.gitdir.should == "#{@repository.project.slug}/foo.git"
  end
  
  it "has a push url" do
    @repository.push_url.should == "#{GitoriousConfig['gitorious_user']}@#{GitoriousConfig['gitorious_host']}:#{@repository.project.slug}/foo.git"
  end
  
  it "has a clone url" do
    @repository.clone_url.should == "git://#{GitoriousConfig['gitorious_host']}/#{@repository.project.slug}/foo.git"
  end
  
  it "has a http url" do
    @repository.http_clone_url.should == "http://git.#{GitoriousConfig['gitorious_host']}/#{@repository.project.slug}/foo.git"
  end
  
  it "has a clone url with the project name, if it's a mainline" do
    @repository.owner = groups(:team_thunderbird)
    @repository.mainline = true
    @repository.clone_url.should == "git://#{GitoriousConfig['gitorious_host']}/#{@repository.project.slug}/foo.git"
  end
  
  it "has a push url with the project name, if it's a mainline" do
    @repository.owner = groups(:team_thunderbird)
    @repository.mainline = true
    @repository.push_url.should == "#{GitoriousConfig['gitorious_user']}@#{GitoriousConfig['gitorious_host']}:#{@repository.project.slug}/foo.git"
  end
  
  it "has a http clone url with the project name, if it's a mainline" do
    @repository.owner = groups(:team_thunderbird)
    @repository.mainline = true
    @repository.http_clone_url.should == "http://git.#{GitoriousConfig['gitorious_host']}/#{@repository.project.slug}/foo.git"
  end
  
  it "has a full repository_path" do
    expected_dir = File.expand_path(File.join(GitoriousConfig["repository_base_path"], 
      "#{@repository.full_hashed_path}.git"))
    @repository.full_repository_path.should == expected_dir
  end
  
  it "inits the git repository" do
    path = @repository.full_repository_path
    Repository.git_backend.expects(:create).with(path).returns(true)
    Repository.create_git_repository(@repository.real_gitdir)
    
    File.exist?(path).should == true
    
    Dir.chdir(path) do
      hooks = File.join(path, "hooks")
      File.exist?(hooks).should == true
      File.symlink?(hooks).should == true
      File.symlink?(File.expand_path(File.readlink(hooks))).should == true
    end
  end
  
  it "clones a git repository" do
    source = repositories(:johans)
    target = @repository
    target_path = @repository.full_repository_path
    
    git_backend = mock("Git backend")
    Repository.expects(:git_backend).returns(git_backend)
    git_backend.expects(:clone).with(target.full_repository_path, 
      source.full_repository_path).returns(true)
    Repository.expects(:create_hooks).returns(true)
    
    Repository.clone_git_repository(target.real_gitdir, source.real_gitdir).should be_true
  end
  
  it "should create the hooks" do
    hooks = "/path/to/hooks"
    path = "/path/to/repository"
    base_path = "#{RAILS_ROOT}/data/hooks"
    
    File.expects(:join).in_sequence.with(GitoriousConfig["repository_base_path"], ".hooks").returns(hooks)
    
    Dir.expects(:chdir).in_sequence.with(path).yields(nil)
    
    File.expects(:symlink?).in_sequence.with(hooks).returns(false)
    File.expects(:exist?).in_sequence.with(hooks).returns(false)
    FileUtils.expects(:ln_s).in_sequence.with(base_path, hooks)
    
    local_hooks = "/path/to/local/hooks"
    File.expects(:join).in_sequence.with(path, "hooks").returns(local_hooks)
    
    File.expects(:exist?).in_sequence.with(local_hooks).returns(true)
    
    File.expects(:join).with(path, "description").in_sequence
    
    File.expects(:open).in_sequence.returns(true)
    
    Repository.create_hooks(path).should be_true
  end
  
  it "deletes a repository" do
    Repository.git_backend.expects(:delete!).with(@repository.full_repository_path).returns(true)
    Repository.delete_git_repository(@repository.real_gitdir)
  end
  
  it "knows if has commits" do
    @repository.stubs(:new_record?).returns(false)
    @repository.stubs(:ready?).returns(true)
    git_mock = mock("Grit::Git")
    @repository.stubs(:git).returns(git_mock)
    head = mock("head")
    head.stubs(:name).returns("master")
    @repository.git.expects(:heads).returns([head])
    @repository.has_commits?.should == true
  end
  
  it "knows if has commits, unless its a new record" do
    @repository.stubs(:new_record?).returns(false)
    @repository.has_commits?.should == false
  end
  
  it "knows if has commits, unless its not ready" do
    @repository.stubs(:ready?).returns(false)
    @repository.has_commits?.should == false
  end
  
  it "should build a new repository by cloning another one" do
    repos = Repository.new_by_cloning(@repository)
    repos.parent.should == @repository
    repos.project.should == @repository.project
    repos.new_record?.should be(true)
  end
  
  it "suggests a decent name for a cloned repository bsed on username" do
    repos = Repository.new_by_cloning(@repository, username="johan")
    repos.name.should == "johan-clone"
    repos = Repository.new_by_cloning(@repository, username=nil)
    repos.name.should == nil
  end
  
  it "has it's name as its to_param value" do
    @repository.save
    @repository.to_param.should == @repository.name
  end
  
  it "finds a repository by name or raises" do
    Repository.find_by_name!(repositories(:johans).name).should == repositories(:johans)
    proc{
      Repository.find_by_name!("asdasdasd")
    }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
  describe "find_by_path" do
    it "finds a repository by its path" do
      repo = projects(:johans).repositories.mainlines.first
      path = File.join(GitoriousConfig['repository_base_path'], 
                        projects(:johans).slug, "#{repo.name}.git")
      Repository.find_by_path(path).should == repo
    end
    
    it "finds a repository by its path, regardless of repository kind" do
      pending "TODO"
      repo = projects(:johans).wiki_repository
      path = File.join(GitoriousConfig['repository_base_path'].chomp("/"), 
                        projects(:johans).slug, "#{repo.name}.git")
      Repository.find_by_path(path).should == repo
    end
  
    it "finds a group repository by its path" do
      repo = repositories(:johans)
      repo.owner = groups(:team_thunderbird)
      repo.mainline = false
      repo.save!
      path = File.join(GitoriousConfig['repository_base_path'], repo.gitdir)
      Repository.find_by_path(path).should == repo    
    end
  
    it "finds a user repository by its path" do
      repo = repositories(:johans)
      repo.owner = users(:johan)
      repo.mainline = false
      repo.save!
      path = File.join(GitoriousConfig['repository_base_path'], repo.gitdir)
      Repository.find_by_path(path).should == repo
    end
  end
  
  it "xmlilizes git paths as well" do
    @repository.to_xml.should include("<gitdir>")
    @repository.to_xml.should include("<clone-url>")
    @repository.to_xml.should include("<push-url>")
  end
  
  it "knows if a user can write to self" do
    @repository.save!
    @repository.writable_by?(users(:johan)).should == true
    @repository.writable_by?(users(:mike)).should == false
    
    @repository.owner = groups(:team_thunderbird)
    @repository.writable_by?(users(:johan)).should == false
    @repository.owner.add_member(users(:mike), Role.committer)
    @repository.writable_by?(users(:mike)).should == true
    
    @repository.owner = users(:johan)
    @repository.writable_by?(users(:johan)).should == true
    @repository.writable_by?(users(:mike)).should == false
  end
  
  it 'publishes a message on create and update' do
    p = proc{
      @repository.save!
    }
    message = find_message_with_queue_and_regexp('/queue/GitoriousRepositoryCreation', /create_git_repository/) {p.call}
    message['command'].should == 'create_git_repository'
    message['arguments'].size.should == 1
    message['arguments'].first.should match(/#{@repository.gitdir}$/)
    message['target_id'].to_i.should == @repository.id
  end

  it "publishes a message on clone" do
    p = proc{
      @repository.parent = repositories(:johans)
      @repository.save!
    }
    message = find_message_with_queue_and_regexp('/queue/GitoriousRepositoryCreation', /clone_git_repository/) {p.call}
    message['command'].should == "clone_git_repository"
    message['arguments'].size.should == 2
    message['arguments'].first.should match(/#{@repository.gitdir}$/)
    message['target_id'].should == @repository.id
  end
  
  it "creates a notification on destroy" do
    @repository.save!
    message = find_message_with_queue_and_regexp(
      '/queue/GitoriousRepositoryDeletion', 
      /delete_git_repository/) {@repository.destroy}
    message['command'].should == 'delete_git_repository'
    message['arguments'].size.should == 1
    message['arguments'].first.should match(/#{@repository.gitdir}$/)
  end
  
  it "has one recent commit" do
    @repository.save!
    repos_mock = mock("Git mock")
    commit_mock = stub_everything("Git::Commit mock")
    repos_mock.expects(:commits).with("master", 1).returns([commit_mock])
    @repository.stubs(:git).returns(repos_mock)
    @repository.stubs(:has_commits?).returns(true)
    heads_stub = mock("head")
    heads_stub.stubs(:name).returns("master")    
    @repository.stubs(:head_candidate).returns(heads_stub)
    @repository.last_commit.should == commit_mock
  end
  
  it "has one recent commit within a given ref" do
    @repository.save!
    repos_mock = mock("Git mock")
    commit_mock = stub_everything("Git::Commit mock")
    repos_mock.expects(:commits).with("foo", 1).returns([commit_mock])
    @repository.stubs(:git).returns(repos_mock)
    @repository.stubs(:has_commits?).returns(true)   
    @repository.expects(:head_candidate).never
    @repository.last_commit("foo").should == commit_mock
  end
  
  it "knows who can delete it" do
    @repository.mainline = true
    @repository.can_be_deleted_by?(users(:johan)).should == false
    @repository.mainline = false
    @repository.can_be_deleted_by?(users(:moe)).should == false
    @repository.can_be_deleted_by?(users(:johan)).should == true
  end
  
  it "has a git method that accesses the repository" do
    # FIXME: meh for stubbing internals, need to refactor that part in Grit
    File.expects(:exist?).at_least(1).with("#{@repository.full_repository_path}/.git").returns(false)
    File.expects(:exist?).at_least(1).with(@repository.full_repository_path).returns(true)
    @repository.git.should be_instance_of(Grit::Repo)
    @repository.git.path.should == @repository.full_repository_path
  end
  
  it "has a head_candidate" do
    heads_stub = mock("head")
    heads_stub.stubs(:name).returns("master")
    git = mock("git backend")
    @repository.stubs(:git).returns(git)
    git.expects(:heads).returns([heads_stub])
    @repository.expects(:has_commits?).returns(true)
    @repository.head_candidate.should == heads_stub
    
    heads_stub = mock("head")
    heads_stub.stubs(:name).returns("foo/bar")
    @repository.expects(:head_candidate).returns(heads_stub)
    @repository.head_candidate_name.should == "foo/bar"
  end
  
  it "has a head_candidate, unless it doesn't have commits" do
    @repository.expects(:has_commits?).returns(false)
    @repository.head_candidate.should == nil
  end
  
  it "has paginated_commits" do
    git = mock("git")
    commits = [mock("commit"), mock("commit")]
    @repository.expects(:git).times(2).returns(git)
    git.expects(:commit_count).returns(120)
    git.expects(:commits).with("foo", 30, 30).returns(commits)
    commits = @repository.paginated_commits("foo", 2, 30)
    commits.should be_instance_of(WillPaginate::Collection)
  end
  
  it "has a count_commits_from_last_week_by_user of 0 if no commits" do
    @repository.expects(:has_commits?).returns(false)
    @repository.count_commits_from_last_week_by_user(users(:johan)).should == 0
  end
  
  it "returns a set of users from a list of commits" do
    commits = []
    users(:johan, :moe).map(&:email).each do |email|
      committer = OpenStruct.new(:email => email)
      commits << OpenStruct.new(:committer => committer, :author => committer)
    end
    users = @repository.users_by_commits(commits)
    users.keys.sort.should == users(:johan, :moe).map(&:email).sort
    users.values.map(&:login).sort.should == users(:johan, :moe).map(&:login).sort
  end
  
  it "know if it's a normal project repository" do
    @repository.project_repo?.should == true
  end
  
  it "know if it's a wiki repo" do
    @repository.kind = Repository::KIND_WIKI
    @repository.wiki?.should == true
  end
  
  it 'has a parent, which is the owner' do
    @repository.owner = groups(:team_thunderbird)
    @repository.breadcrumb_parent.should == groups(:team_thunderbird)
    @repository.owner = users(:johan)
    @repository.breadcrumb_parent.should == users(:johan)
    @repository.owner = projects(:johans)
    @repository.breadcrumb_parent.should == projects(:johans)
  end
  
  it 'has a parent, which is the project for mainlines' do
    @repository.mainline = true
    @repository.owner = groups(:team_thunderbird)
    @repository.breadcrumb_parent.should == projects(:johans)
    @repository.owner = users(:johan)
    @repository.breadcrumb_parent.should == projects(:johans)
    @repository.owner = projects(:johans)
    @repository.breadcrumb_parent.should == projects(:johans)
    @repository.mainline = false
    @repository.owner = projects(:johans)
    @repository.breadcrumb_parent.should == projects(:johans)
  end
  
  it 'should return its name as title' do
    @repository.name.should == @repository.title
  end
  
  it "returns a list of committers depending on owner type" do
    repo = repositories(:johans2)
    
    repo.owner = projects(:johans)
    repo.committers.should == [users(:johan)]
    
    repo.owner = users(:johan)
    repo.committers.should == [users(:johan)]
    
    repo.owner = groups(:team_thunderbird)
    repo.committers.should == groups(:team_thunderbird).members
    
    repo.owner.add_member(users(:moe), Role.committer)
    repo.reload
    repo.committers.map(&:login).should include(users(:moe).login)
  end
  
  it "sets a hash on create" do
    @repository.new_record?.should == true
    @repository.save!
    @repository.hashed_path.should_not == nil
    @repository.hashed_path.should match(/[a-z0-9]{40}/)
  end
  
  it "know the full hashed path" do
    @repository.hashed_path = "a"*40
    @repository.full_hashed_path.should == "aaa/aaa/#{'a'*34}"
  end
  
  it "should allow changing ownership from a user to a group" do
    repo = repositories(:johans)
    repo.change_owner_to(groups(:team_thunderbird))
    repo.owner.should == groups(:team_thunderbird)
    repo.change_owner_to(users(:johan))
    repo.owner.should == groups(:team_thunderbird)
  end
  
  it "downcases the name before validation" do
    repo = new_repos(:name => "FOOBAR")
    repo.save!
    repo.reload.name.should == "foobar"
  end
  
  describe "participant groups" do
    before(:each) do
      @repo = repositories(:moes)
    end
    
    it "has a set of groups" do
      @repo.groups.should == [groups(:team_thunderbird)]
    end
    
    it "collects all the groups' members" do
      @repo.group_members.should == groups(:team_thunderbird).members
    end
    
    it "includes the groups' members in #committers" do
      @repo.committers.should include(groups(:team_thunderbird).members.first)
    end
    
    it "only include unique users in #committers" do
      groups(:team_thunderbird).add_member(users(:moe), Role.committer)
      @repo.committers.select{|u| u == users(:moe)}.size.should == 1
    end
    
    it "should be possible to exclude the groups in #committers" do
      users = @repo.committers(:exclude_groups => true).map(&:login)
      users.should_not include(groups(:team_thunderbird).members.first.login)
    end
  end
  
  describe "observers" do
    it "sends an email to the admin if there's a parent" do
      Mailer.expects(:deliver_new_repository_clone).with(@repository).returns(true)
      @repository.parent = repositories(:johans)
      @repository.save!
    end
    
    it "does not send an email to the admin if there's not a parent parent" do
      Mailer.expects(:deliver_new_repository_clone).never
      @repository.parent = nil
      @repository.save!
    end
  end
end
