require File.dirname(__FILE__) + '/../spec_helper'

describe Repository do
  before(:each) do
    @repository = new_repos
  end
  
  def new_repos(opts={})
    Repository.new({
      :name => "foo",
      :project => projects(:johans),
      :user => users(:johan)
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
  
  it "sets itself as mainline if it's the first repository for a project" do
    projects(:johans).repositories.destroy_all
    projects(:johans).repositories.reload.size.should == 0
    @repository.save
    @repository.mainline?.should == true
  end
  
  it "doesnt set itself as mainline if there's more than one repos" do
    @repository.save
    @repository.mainline?.should == false
  end
  
  it "has a gitdir name" do
    @repository.gitdir.should == "#{@repository.project.slug}/foo.git"
  end
  
  it "has a push url" do
    @repository.push_url.should == "git@#{GitoriousConfig['gitorious_host']}:#{@repository.project.slug}/foo.git"
  end
  
  it "has a clone url" do
    @repository.clone_url.should == "git://#{GitoriousConfig['gitorious_host']}/#{@repository.project.slug}/foo.git"
  end
  
  it "has a http url" do
    @repository.http_clone_url.should == "http://git.#{GitoriousConfig['gitorious_host']}/#{@repository.project.slug}/foo.git"
  end
  
  it "should assign the creator as a comitter on create" do 
    @repository.save!
    @repository.reload
    @repository.committers.should include(users(:johan))
  end
  
  it "has a full repository_path" do
    expected_dir = File.expand_path(File.join(GitoriousConfig["repository_base_path"], 
      projects(:johans).slug, "foo.git"))
    @repository.full_repository_path.should == expected_dir
  end
  
  it "inits the git repository" do
    Repository.git_backend.should_receive(:create).with(@repository.full_repository_path).and_return(true)
    Repository.create_git_repository(@repository.gitdir)
  end
  
  it "clones a git repository" do
    source = repositories(:johans)
    target = @repository
    Repository.git_backend.should_receive(:clone).with(target.full_repository_path, 
      source.full_repository_path).and_return(true)
    Repository.clone_git_repository(target.gitdir, source.gitdir)
  end
  
  it "deletes a repository" do
    Repository.git_backend.should_receive(:delete!).with(@repository.full_repository_path).and_return(true)
    Repository.delete_git_repository(@repository.gitdir)
  end
  
  it "knows if has commits" do
    @repository.stub!(:new_record?).and_return(false)
    @repository.stub!(:ready?).and_return(true)
    git_mock = mock("Grit::Git")
    @repository.stub!(:git).and_return(git_mock)
    head = mock("head")
    head.stub!(:name).and_return("master")
    @repository.git.should_receive(:heads).and_return([head])
    @repository.has_commits?.should == true
  end
  
  it "knows if has commits, unless its a new record" do
    @repository.stub!(:new_record?).and_return(false)
    @repository.has_commits?.should == false
  end
  
  it "knows if has commits, unless its not ready" do
    @repository.stub!(:ready?).and_return(false)
    @repository.has_commits?.should == false
  end
  
  it "should build a new repository by cloning another one" do
    repos = Repository.new_by_cloning(@repository)
    repos.parent.should == @repository
    repos.project.should == @repository.project
  end
  
  it "suggests a decent name for a cloned repository bsed on username" do
    repos = Repository.new_by_cloning(@repository, username="johan")
    repos.name.should == "johans-clone"
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
  
  it "xmlilizes git paths as well" do
    @repository.to_xml.should include("<gitdir>")
    @repository.to_xml.should include("<clone-url>")
    @repository.to_xml.should include("<push-url>")
  end
  
  it "adds an user as a comitter to itself" do
    @repository.save
    users(:moe).can_write_to?(@repository).should == false
    @repository.add_committer(users(:moe))
    users(:moe).can_write_to?(@repository).should == true
  end
  
  it "creates a Task on create and update" do
    proc{
      @repository.save!
    }.should change(Task, :count)
    task = Task.find(:first, :conditions => ["target_class = 'Repository'"], :order => "id desc")
    task.command.should == "create_git_repository"
    task.arguments.size.should == 1
    task.arguments.first.should match(/#{@repository.gitdir}$/)
    task.target_id.should == @repository.id
  end
  
  it "creates a clone task if there's a parent" do
    proc{
      @repository.parent = repositories(:johans)
      @repository.save!
    }.should change(Task, :count)
    task = Task.find(:first, :conditions => ["target_class = 'Repository'"], :order => "id desc")
    task.command.should == "clone_git_repository"
    task.arguments.size.should == 2
    task.arguments.first.should match(/#{@repository.gitdir}$/)
    task.target_id.should == @repository.id
  end
  
  it "creates a Task on destroy" do
    @repository.save!
    proc{
      @repository.destroy
    }.should change(Task, :count)
    task = Task.find(:first, :conditions => ["target_class = 'Repository'"], :order => "id desc")
    task.command.should == "delete_git_repository"
    task.arguments.size.should == 1
    task.arguments.first.should match(/#{@repository.gitdir}$/)
  end
  
  it "has one recent commit" do
    @repository.save!
    repos_mock = mock("Git mock")
    commit_mock = mock("Git::Commit mock", :null_object => true)
    repos_mock.should_receive(:commits).with("master", 1).and_return(commit_mock)
    commit_mock.should_receive(:first).and_return(commit_mock)
    @repository.stub!(:git).and_return(repos_mock)
    @repository.stub!(:has_commits?).and_return(true)
    heads_stub = mock("head")
    heads_stub.stub!(:name).and_return("master")    
    @repository.stub!(:head_candidate).and_return(heads_stub)
    @repository.last_commit.should == commit_mock
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
    File.should_receive(:exist?).at_least(1).with("#{@repository.full_repository_path}/.git").and_return(false)
    File.should_receive(:exist?).at_least(1).with(@repository.full_repository_path).and_return(true)
    @repository.git.should be_instance_of(Grit::Repo)
    @repository.git.path.should == @repository.full_repository_path
  end
  
  it "has a head_candidate" do
    heads_stub = mock("head")
    heads_stub.stub!(:name).and_return("master")
    git = mock("git backend")
    @repository.stub!(:git).and_return(git)
    git.should_receive(:heads).and_return([heads_stub])
    @repository.should_receive(:has_commits?).and_return(true)
    @repository.head_candidate.should == heads_stub
  end
  
  it "has a head_candidate, unless it doesn't have commits" do
    @repository.should_receive(:has_commits?).and_return(false)
    @repository.head_candidate.should == nil
  end
  
  describe "observers" do
    it "sends an email to the admin if there's a parent" do
      Mailer.should_receive(:deliver_new_repository_clone).with(@repository).and_return(true)
      @repository.parent = repositories(:johans)
      @repository.save!
    end
    
    it "does not send an email to the admin if there's not a parent parent" do
      Mailer.should_not_receive(:deliver_new_repository_clone).with(@repository).and_return(true)
      @repository.parent = nil
      @repository.save!
    end
  end
end
