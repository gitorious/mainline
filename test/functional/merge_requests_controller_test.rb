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

class MergeRequestsControllerTest < ActionController::TestCase
  
  should_render_in_site_specific_context
  
	def setup
		@project = projects(:johans)
    grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(grit)
		@source_repository = repositories(:johans2)
		@target_repository = repositories(:johans)
		@merge_request = merge_requests(:moes_to_johans_open)
		@merge_request.stubs(:calculate_merge_base).returns("ff")
		@merge_request.stubs(:commit_merged?).returns(true)
		@merge_request.create_new_version
		@merge_request.stubs(:commits_for_selection).returns([])
		assert_not_nil @merge_request.versions.last
	end
	
	context "#index (GET)" do		
		should " not require login" do
			session[:user_id] = nil
			get :index, :project_id => @project.to_param,
				:repository_id => @target_repository.to_param
			assert_response :success
		end
		
		should "gets all the merge requests in the repository" do
		  %w(html xml).each do |format|
  			get :index, :project_id => @project.to_param,
  				:repository_id => @target_repository.to_param,
  				:format => format
  			assert_equal @target_repository.merge_requests.open, assigns(:open_merge_requests)
  			assert_equal @target_repository.merge_requests.closed, assigns(:recently_closed_merge_requests)
  		end
		end
		
		should "gets a comment count for" do
			get :index, :project_id => @project.to_param,
				:repository_id => @target_repository.to_param
			assert_equal @target_repository.comments.count, assigns(:comment_count)
		end
		
		should "filter on status" do
		  @merge_request.update_attribute(:status, MergeRequest::STATUS_MERGED)
		  get :index, :project_id => @project.to_param,
				:repository_id => @target_repository.to_param,
				:status => "merged"
			assert_response :success
			assert_equal [@merge_request], assigns(:open_merge_requests)
	  end
	end
	
	def stub_commits(merge_request)
    commits = %w(9dbb89110fc45362fc4dc3f60d960381 6823e6622e1da9751c87380ff01a1db1 526fa6c0b3182116d8ca2dc80dedeafb 286e8afb9576366a2a43b12b94738f07).collect do |sha|
      m = mock
      m.stubs(:id).returns(sha)
      m.stubs(:id_abbrev).returns(sha[0..7])
      m.stubs(:committer).returns(Grit::Actor.new("bob", "bob@example.com"))
      m.stubs(:author).returns(Grit::Actor.new("bob", "bob@example.com"))
      m.stubs(:short_message).returns("bla bla")
      m.stubs(:committed_date).returns(3.days.ago)
      m.stubs(:to_patch).returns("From: #{sha}\nSubject: [PATCH]")
      m
    end
	 merge_request.stubs(:commits_for_selection).returns(commits)
	 merge_request.stubs(:commits_to_be_merged).returns(commits[0..1])
	end
	
	context "#show (GET)" do		
		should " not require login" do
			session[:user_id] = nil
			MergeRequest.expects(:find).returns(@merge_request)
			stub_commits(@merge_request)
			[@merge_request.source_repository, @merge_request.target_repository].each do |r|
				r.stubs(:git).returns(stub_everything("Git"))
			end
			get :show, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param,
				:id => @merge_request.id
			assert_response :success
			assert_select "h3", :content => "Add a new comment:"
		end
		
		should "get a list of the commits to be merged" do
      %w(html patch xml).each do |format|
  			MergeRequest.expects(:find).returns(@merge_request)
        stub_commits(@merge_request)
  			get :show, :project_id => @project.to_param, 
  				:repository_id => @target_repository.to_param,
  				:id => @merge_request.id, :format => format
  			assert_response :success
  			assert_equal 2, assigns(:commits).size
			end
		end

		
		should "allow committers to change status" do
		  login_as :johan
  		@project = projects(:johans)
  		@project.owner = groups(:team_thunderbird)
  		@project.owner.add_member(users(:johan), Role.member)
  		@repository = repositories(:johans2)
  		@mainline_repository = repositories(:johans)
  		@merge_request = merge_requests(:moes_to_johans)
  		@merge_request.stubs(:calculate_merge_base).returns('ff0')
  		@merge_request.create_new_version
  		@merge_request.stubs(:commit_merged?).returns(true)
  		stub_commits(@merge_request)
  		
  		MergeRequest.expects(:find).returns(@merge_request)
  		git_stub = stub_everything("Grit", :commit_deltas_from => [])
  		[@merge_request.source_repository, @merge_request.target_repository].each do |r|
  			r.stubs(:git).returns(git_stub)
  		end
  		get :show, :project_id => @project.to_param, 
  			:repository_id => repositories(:johans).name,
  			:id => @merge_request.id
  		assert_match(/Update merge request/, @response.body) #TODO assert_select proper
    end
	end

	context "#new (GET)" do
	  setup do
	    Grit::Repo.any_instance.stubs(:heads).returns([])
    end
    
		should "requires login" do
			session[:user_id] = nil
			get :new, :project_id => @project.to_param, 
				:repository_id => @source_repository.to_param
			assert_redirected_to(new_sessions_path)
		end
		
		should "is successful" do
			login_as :johan
			get :new, :project_id => @project.to_param, 
				:repository_id => @source_repository.to_param
			assert_response :success
		end
		
		should 'assign to @project even when accessed through a user' do
		  johan = users(:johan)
		  login_as :johan
		  @source_repository.owner = johan
		  @source_repository.save!
		  get :new, :user_id => johan.to_param, :repository_id => @source_repository.to_param, :project_id => @project.to_param
		  assert_response :success
	  end
		
		should "assigns the new merge_requests' source_repository" do
			login_as :johan
			get :new, :project_id => @project.to_param, 
				:repository_id => @source_repository.to_param
			assert_equal @source_repository, assigns(:merge_request).source_repository
		end
		
		should "gets a list of possible target clones" do
			login_as :johan
			get :new, :project_id => @project.to_param, 
				:repository_id => @source_repository.to_param
			assert_equal [repositories(:johans)], assigns(:repositories)
		end
		
		should "set a default mainline target repo id" do
		  login_as :johan
		  get :new, :project_id => @project.to_param, :repository_id => @source_repository.to_param
		  assert_equal repositories(:johans).id, assigns(:merge_request).target_repository_id
	  end
	end
	
	def do_post(data={})
		post :create, :project_id => @project.to_param, 
			:repository_id => @source_repository.to_param, :merge_request => {
				:target_repository_id => @target_repository.id,
				:ending_commit => '6823e6622e1da9751c87380ff01a1db1'
			}.merge(data)
	end
	
	context "#create (POST)" do
	  setup do
	    Grit::Repo.any_instance.stubs(:heads).returns([])
    end
    
		should "require login" do
			session[:user_id] = nil
			do_post
			assert_redirected_to(new_sessions_path)
		end
		
		should "scope to the source_repository" do
			login_as :johan
			do_post
			assert_equal @source_repository, assigns(:merge_request).source_repository
		end
		
		should "scope to the current_user" do
			login_as :johan
			do_post
			assert_equal users(:johan), assigns(:merge_request).user
		end
		
		should "create the record on successful data" do
			login_as :johan
			mock_token = mock("Mocked access token")
			mock_token.stubs(:token).returns("key")
			mock_token.stubs(:secret).returns("secret")
			mock_token.stubs(:authorize_url).returns("http://oauth.example/authorize?key=123")
			@controller.expects(:obtain_oauth_request_token).returns(mock_token)
			assert_difference("MergeRequest.count") do
				do_post
				assert_response :redirect
				result = assigns(:merge_request)
				assert_equal(terms_accepted_project_repository_merge_request_path(@source_repository.project, @target_repository, result), session[:return_to])
      end
		end
		
		should 'not require off-site signoff of terms unless the repository needs it' do
		  login_as(:johan)
      post :create, :project_id => @project.to_param, 
              :repository_id => @target_repository.to_param, :merge_request => {
                :target_repository_id => @source_repository.id,
                :ending_commit => '6823e6622e1da9751c87380ff01a1db1'
              }
		  result = assigns(:merge_request)
		  assert !result.acceptance_of_terms_required?
		  assert result.open?
			assert_match(/sent a merge request to "#{@source_repository.name}"/i, flash[:success])
	  end
	  
	  should "create an event when the request doesn't require signof" do
	    login_as :johan
	    assert_difference("@project.events.count") do
	      post :create, :project_id => @project.to_param, 
                :repository_id => @target_repository.to_param, :merge_request => {
                  :target_repository_id => @source_repository.id,
                  :ending_commit => '6823e6622e1da9751c87380ff01a1db1'
                }
      end
    end
		
		should "it re-renders on invalid data, with the target repos list" do
			login_as :johan
			do_post :target_repository => nil
			assert_response :success
			assert_template(("merge_requests/new"))
			assert_equal [repositories(:johans)], assigns(:repositories)
		end
	end
	
	context "Merge request landing page" do
	  should "GET the mergerequest landing page" do
		  login_as :johan
		  session[:return_to] = "/foo/bar"
		  get :oauth_return
		  assert_response :redirect
		  assert_redirected_to "/foo/bar"
	  end
	  
	  should "route the merge_request_landing_page" do
      assert_recognizes({
        :controller => "merge_requests",
        :action => "oauth_return",
      }, "/merge_request_landing_page")
    end
    
    should "have a named route" do
      assert_equal "/merge_request_landing_page", merge_request_landing_page_path
    end
  end
	
	context 'Terms accepted (GET)' do
	  setup do
		  @merge_request = @source_repository.proposed_merge_requests.new(:proposal => 'Would like this to be merged', :user => users(:johan), :ending_commit => '6823e6622e1da9751c87380ff01a1db1', :target_repository => @target_repository)
		  assert @merge_request.save
		  @merge_request.stubs(:commits_to_be_merged).returns([])
		  MergeRequest.stubs(:find).returns(@merge_request)
		  login_as :johan
    end

		should 'set the status to open when done authenticating thru OAuth' do
	    @merge_request.stubs(:valid_oauth_credentials?).returns(true)
      get :terms_accepted, {:project_id => @project.to_param,
        :repository_id => @target_repository.to_param,
        :id => @merge_request.to_param}
      assert_response :redirect
      assert @merge_request.open?
	  end
	  
	  should 'not set the status to open if OAuth authentication has not been performed' do
	    @merge_request.stubs(:valid_oauth_credentials?).returns(false)
      get :terms_accepted, :project_id => @project.to_param,
        :repository_id => @target_repository.to_param,
        :id => @merge_request.to_param
      assert_response :redirect
      assert !@merge_request.open?
    end
  end
	
	context "#edit (GET)" do		
		should "requires login" do
			session[:user_id] = nil
			get :edit, :project_id => @project.to_param, :repository_id => @target_repository.to_param,
				:id => @merge_request
			assert_redirected_to(new_sessions_path)
		end
		
		should "requires ownership to edit" do
			login_as :moe
			get :edit, :project_id => @project.to_param, :repository_id => @target_repository.to_param,
				:id => @merge_request
			assert_match(/you're not the owner/i, flash[:error])
			assert_response :redirect
		end
		
		should "is successfull" do
			login_as :johan
			get :edit, :project_id => @project.to_param, :repository_id => @target_repository.to_param,
				:id => @merge_request
			assert_response :success
		end
		
		should "gets a list of possible target clones" do
			login_as :johan
			get :edit, :project_id => @project.to_param, :repository_id => @target_repository.to_param,
				:id => @merge_request
			assert_equal [@source_repository], assigns(:repositories)
		end
	end
	
	def do_put(data={})
		put :update, :project_id => @project.to_param, 
			:repository_id => @target_repository.to_param, 
			:id => @merge_request,
			:merge_request => {
				:target_repository_id => @target_repository.id,
			}.merge(data)
	end

  def do_commit_status_get(data = {})
    options = {:project_id => @project.to_param,:repository_id => @target_repository.to_param,:id => @merge_request.id}.merge(data)
    get :commit_status, options
  end
  
  context 'commit_merged (GET)' do
    setup do
      login_as :johan
      @merge_request.stubs(:commit_merged?).with('ffc').returns(false)
      @merge_request.stubs(:commit_merged?).with('ffo').returns(true)
      MergeRequest.stubs(:find).returns(@merge_request)
    end
    
    should 'return false if the given commit has not been merged' do
      do_commit_status_get(:commit_id => 'ff0')
      assert_response :success
      assert_equal 'true', @response.body
    end

    should 'return true if the given commit has been merged' do
      do_commit_status_get(:commit_id => 'ffc')
      assert_response :success
      assert_equal 'false', @response.body
    end
  end
	
	context "#update (PUT)" do		
		should "requires login" do
			session[:user_id] = nil
			do_put
			assert_redirected_to(new_sessions_path)
		end
		
		should "requires ownership to update" do
			login_as :moe
			do_put
			assert_match(/you're not the owner/i, flash[:error])
			assert_response :redirect
		end
		
		should "scopes to the source_repository" do
			login_as :johan
			do_put
			assert_equal @source_repository, assigns(:merge_request).source_repository
		end
		
		should "scopes to the current_user" do
			login_as :johan
			do_put
			assert_equal users(:johan), assigns(:merge_request).user
		end
		
		should "updates the record on successful data" do
			login_as :johan
			do_put :proposal => "hai, plz merge kthnkxbye"
			
			assert_redirected_to(project_repository_merge_request_path(@project, @target_repository, @merge_request))
			assert_match(/merge request was updated/i, flash[:success])
			assert_equal "hai, plz merge kthnkxbye", @merge_request.reload.proposal
		end
		
		should "it re-renders on invalid data, with the target repos list" do
			login_as :johan
			do_put :target_repository => nil
			assert_response :success
			assert_template(("merge_requests/edit"))
			assert_equal [@source_repository], assigns(:repositories)
		end
		
		should "only allows the owner to update" do
			login_as :moe
			do_put
			assert_no_difference("MergeRequest.count") do
				assert_redirected_to(project_repository_path(@project, @target_repository))
				assert_equal nil, flash[:success]
				assert_match(/You're not the owner of this merge request/i, flash[:error])
      end
		end
		
	end
	
	def do_resolve_put(data={})
		put :resolve, :project_id => @project.to_param, 
			:repository_id => @target_repository.to_param, 
			:id => @merge_request,
			:merge_request => {
				:status => 'merge',
			}.merge(data)
	end
	
	context "#resolve (PUT)" do		
		should "requires login" do
			session[:user_id] = nil
			do_resolve_put
			assert_redirected_to(new_sessions_path)
		end
		
		should "requires ownership to resoble" do
			login_as :moe
			do_resolve_put
			assert_match(/you're not permitted/i, flash[:error])
			assert_response :redirect
		end
		
		should "updates the status" do
			login_as :johan
			do_resolve_put
			assert_equal "The merge request was marked as merged", flash[:notice]
			assert_response :redirect
		end
		
		should 'not update the status if the merge request does not allow transitioning' do
		  MergeRequest.any_instance.stubs(:can_transition_to?).returns(false)
		  login_as :johan
		  do_resolve_put
		  assert_equal "The merge request could not be marked as merged", flash[:error]
	  end
	  
	  should 'send an email notification to the user when resolving a merge request' do
	    login_as :johan
	    @merge_request.status = MergeRequest::STATUS_OPEN
	    @merge_request.save
	    assert @merge_request.can_transition_to?(:'in_verification')
	    assert_incremented_by(@merge_request.user.sent_messages, :size, 1) do
  	    put :resolve, :project_id => @project.to_param, 
    			:repository_id => @target_repository.to_param, 
    			:id => @merge_request,
    			:merge_request => {
    				:status => 'in_verification',
    				:reason => 'Not too good'
    			}
    		assert_response :redirect
    	end
  		assert @merge_request.reload.verifying?
    end
	  
	  should 'set the reason when resolving with a message' do
	    login_as :johan
	    put :resolve, :project_id => @project.to_param, 
  			:repository_id => @target_repository.to_param, 
  			:id => @merge_request,
  			:merge_request => {
  				:status => 'merge',
  				:reason => 'Not too good'
  			}
			assert_equal "The merge request was marked as merged", flash[:notice]
	    assert_equal("Not too good", assigns(:merge_request).reason)
    end
    
    should 'set the updated_by to current_user when resolving' do
	    @merge_request.user = users(:mike)
	    assert @merge_request.save
	    login_as :johan
	    do_resolve_put
	    assert_equal users(:johan), @merge_request.reload.updated_by
    end
	end
	
	context "#get commit_list" do
	  setup do
	    @commits = %w(ffcffcffc ff0ff0ff0).collect do |sha|
	      m = mock
	      m.stubs(:id).returns(sha)
	      m.stubs(:id_abbrev).returns(sha[0..7])
	      m.stubs(:committer).returns(Grit::Actor.new("bob", "bob@example.com"))
	      m.stubs(:author).returns(Grit::Actor.new("bob", "bob@example.com"))
	      m.stubs(:short_message).returns("bla bla")
	      m.stubs(:committed_date).returns(3.days.ago)
	      m
      end
	    merge_request = MergeRequest.new
	    merge_request.stubs(:commits_for_selection).returns(@commits)
	    MergeRequest.expects(:new).returns(merge_request)
    end
    
	  should " render a list of commits that can be merged" do
	    login_as :johan
			post :commit_list, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param,
				:merge_request => {}
			assert_equal @commits, assigns(:commits)
    end
  end
  
  def do_reopen_put
      put :reopen, :project_id => @project.to_param, 
        :repository_id => @repository.to_param,
        :id => @merge_request    
  end
  
  context 'PUT #reopen' do
    setup do
      @merge_request = merge_requests(:moes_to_johans_open)
      @merge_request.reject
      @repository = @merge_request.target_repository
      @project = @repository.project
    end
    
    should 'not be allowed for non-owners' do
      username = :moe
      assert !@merge_request.resolvable_by?(users(username))
      login_as(username)
      do_reopen_put
      assert_response :redirect
      assert @merge_request.reload.rejected?
    end
    
    should 'allow owners to reopen merge requests and add an event' do
      username = :johan
      assert @merge_request.resolvable_by?(users(username))
      login_as(username)
      assert_incremented_by(@project.events, :size, 1) do
        do_reopen_put
        assert_response :redirect
        assert @merge_request.reload.open?
        @project.events.reload
      end
    end
  end
  
  context "GET #target_branches" do
    should "retrive a list of the target repository branches" do
      grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
      MergeRequest.any_instance.expects(:target_branches_for_selection).returns(grit.branches)
      
      login_as :johan
			post :target_branches, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param,
				:merge_request => {:target_repository_id => repositories(:johans).id}
			assert_response :success
			assert_equal grit.branches, assigns(:target_branches)
    end
  end
  
  context 'GET #version' do
    should 'retrieve the commits in a specific version' do
      MergeRequest.stubs(:find).returns(@merge_request)
      login_as :johan
      @merge_request.expects(:commit_diff_from_tracking_repo).with(10).returns([])
      get :version, :project_id => @project.to_param, :repository_id => @target_repository.to_param,
        :id => @merge_request.to_param, :version => 10
      assert_response :success
    end
  end
	
	def do_delete
		delete :destroy, :project_id => @project.to_param, 
			:repository_id => @target_repository.to_param, 
			:id => @merge_request
	end
	
	context "#destroy (DELETE)" do		
		should "requires login" do
			session[:user_id] = nil
			do_delete
			assert_redirected_to(new_sessions_path)
		end
		
		should "scopes to the source_repository" do
			login_as :johan
			do_delete
			assert_equal @source_repository, assigns(:merge_request).source_repository
		end
		
		should "deletes the record" do
			login_as :johan
			do_delete
			assert_redirected_to(project_repository_path(@project, @target_repository))
			assert_match(/merge request was retracted/i, flash[:success])
			assert_nil MergeRequest.find_by_id(@merge_request.id)
		end
		
		should "only allows the owner to delete" do
			login_as :moe
			do_delete
			assert_no_difference("MergeRequest.count") do
				assert_redirected_to(project_repository_path(@project, @target_repository))
				assert_equal nil, flash[:success]
				assert_match(/You're not the owner of this merge request/i, flash[:error])
      end
		end
	end
	
	context 'Redirection from the outside' do
	  setup do
	    @merge_request = merge_requests(:moes_to_johans)
    end
    
    should 'redirect to the correct URL when supplying only an id' do
      get :direct_access, :id => @merge_request.to_param
      assert_redirected_to({
        :action => 'show', 
        :project_id => @merge_request.target_repository.project,
        :repository_id => @merge_request.target_repository,
        :id => @merge_request})
    end
  end
  
  context "routing" do
    should "route for repositories thats owned by users with dots in their username on #index" do
      assert_recognizes({
        :controller => "merge_requests", 
        :action => "index", 
        :user_id => "mc.hammer",
        :project_id => "myproject",
        :repository_id => "myrepo",
      }, {:path => "/~mc.hammer/myproject/myrepo/merge_requests", :method => :get})
      assert_generates("/~mc.hammer/myproject/myrepo/merge_requests", {
        :controller => "merge_requests", 
        :action => "index", 
        :user_id => "mc.hammer",
        :project_id => "myproject",
        :repository_id => "myrepo",
      })
    end
    
    should "route for repositories thats owned by users with dots in their username on #show" do
      assert_recognizes({
        :controller => "merge_requests", 
        :action => "show", 
        :user_id => "mc.hammer",
        :project_id => "myproject",
        :repository_id => "myrepo",
        :id => "42"
      }, {:path => "/~mc.hammer/myproject/myrepo/merge_requests/42", :method => :get})
      assert_generates("/~mc.hammer/myproject/myrepo/merge_requests/42", {
        :controller => "merge_requests", 
        :action => "show", 
        :user_id => "mc.hammer",
        :project_id => "myproject",
        :repository_id => "myrepo",
        :id => "42"
      })
    end
  end

end
