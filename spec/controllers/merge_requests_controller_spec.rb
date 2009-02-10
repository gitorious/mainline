#--
#		Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
#		Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#
#		This program is free software: you can redistribute it and/or modify
#		it under the terms of the GNU Affero General Public License as published by
#		the Free Software Foundation, either version 3 of the License, or
#		(at your option) any later version.
#
#		This program is distributed in the hope that it will be useful,
#		but WITHOUT ANY WARRANTY; without even the implied warranty of
#		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
#		GNU Affero General Public License for more details.
#
#		You should have received a copy of the GNU Affero General Public License
#		along with this program.	If not, see <http://www.gnu.org/licenses/>.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe MergeRequestsController do
	
	before(:each) do
		@project = projects(:johans)
		git = mock
		git.stubs(:branches).returns([])
		Repository.any_instance.stubs(:git).returns(git)
		@source_repository = repositories(:johans2)
		@target_repository = repositories(:johans)
		@merge_request = merge_requests(:moes_to_johans)
		@merge_request.stubs(:commits_for_selection).returns([])
	end
	
	describe "#index (GET)" do
		def do_get
			get :index, :project_id => @project.to_param,
				:repository_id => @target_repository.to_param
		end		 
		
		it "should not require login" do
			session[:user_id] = nil
			do_get
			response.should_not redirect_to(new_sessions_path)			
		end
		
		it "gets all the merge requests in the repository" do
			do_get
			assigns(:merge_requests).should == @target_repository.merge_requests
		end
		
		it "gets a comment count for" do
			do_get
			assigns(:comment_count).should == @target_repository.comments.count
		end
	end
	
	describe "#show (GET)" do
		def do_get
			get :show, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param,
				:id => @merge_request.id
		end
		
		it "should not require login" do
			session[:user_id] = nil
			MergeRequest.expects(:find).returns(@merge_request)
			[@merge_request.source_repository, @merge_request.target_repository].each do |r|
				r.stubs(:git).returns(stub_everything("Git"))
			end
			do_get
			response.should_not redirect_to(new_sessions_path)			
		end
		
		it "gets a list of the commits to be merged" do
			MergeRequest.expects(:find).returns(@merge_request)
      commits = %w(9dbb89110fc45362fc4dc3f60d960381 6823e6622e1da9751c87380ff01a1db1 526fa6c0b3182116d8ca2dc80dedeafb 286e8afb9576366a2a43b12b94738f07).collect do |sha|
        m = mock
        m.stubs(:id).returns(sha)
        m
      end
      @merge_request.stubs(:commits_for_selection).returns(commits)
			do_get
			assigns[:commits].size.should == 4
		end
	end

	describe "#new (GET)" do
		def do_get
			get :new, :project_id => @project.to_param, 
				:repository_id => @source_repository.to_param
		end
		
		it "requires login" do
			session[:user_id] = nil
			do_get
			response.should redirect_to(new_sessions_path)
		end
		
		it "is successful" do
			login_as :johan
			do_get
			response.should be_success
		end
		
		it "assigns the new merge_requests' source_repository" do
			login_as :johan
			do_get
			assigns(:merge_request).source_repository.should == @source_repository
		end
		
		it "gets a list of possible target clones" do
			login_as :johan
			do_get
			assigns(:repositories).should == [repositories(:johans)]
		end
	end
	
	describe "#create (POST)" do
		def do_post(data={})
			post :create, :project_id => @project.to_param, 
				:repository_id => @source_repository.to_param, :merge_request => {
					:target_repository_id => @target_repository.id,
					:ending_commit => '6823e6622e1da9751c87380ff01a1db1'
				}.merge(data)
		end
		
		it "requires login" do
			session[:user_id] = nil
			do_post
			response.should redirect_to(new_sessions_path)
		end
		
		it "scopes to the source_repository" do
			login_as :johan
			do_post
			assigns[:merge_request].source_repository.should == @source_repository
		end
		
		it "scopes to the current_user" do
			login_as :johan
			do_post
			assigns[:merge_request].user.should == users(:johan)
		end
		
		it "creates the record on successful data" do
			login_as :johan
			proc {
				do_post
				response.should redirect_to(project_repository_path(@project, @source_repository))
				flash[:success].should match(/sent a merge request to "#{@target_repository.name}"/i)
			}.should change(MergeRequest, :count)
		end
		
		it "it re-renders on invalid data, with the target repos list" do
			login_as :johan
			do_post :target_repository => nil
			response.should be_success
			response.should render_template("merge_requests/new")
			assigns[:repositories].should == [repositories(:johans)]
		end
	end
	
	describe "#edit (GET)" do
		def do_get
			get :edit, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param,
				:id => @merge_request
		end
		
		it "requires login" do
			session[:user_id] = nil
			do_get
			response.should redirect_to(new_sessions_path)
		end
		
		it "requires ownership to edit" do
			login_as :moe
			do_get
			flash[:error].should match(/you're not the owner/i)
			response.should be_redirect
		end
		
		it "is successfull" do
			login_as :johan
			do_get
			response.should be_success
		end
		
		it "gets a list of possible target clones" do
			login_as :johan
			do_get
			assigns[:repositories].should == [@source_repository]
		end
	end
	
	describe "#update (PUT)" do
		def do_put(data={})
			put :update, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param, 
				:id => @merge_request,
				:merge_request => {
					:target_repository_id => @target_repository.id,
				}.merge(data)
		end
		
		it "requires login" do
			session[:user_id] = nil
			do_put
			response.should redirect_to(new_sessions_path)
		end
		
		it "requires ownership to update" do
			login_as :moe
			do_put
			flash[:error].should match(/you're not the owner/i)
			response.should be_redirect
		end
		
		it "scopes to the source_repository" do
			login_as :johan
			do_put
			assigns[:merge_request].source_repository.should == @source_repository
		end
		
		it "scopes to the current_user" do
			login_as :johan
			do_put
			assigns[:merge_request].user.should == users(:johan)
		end
		
		it "updates the record on successful data" do
			login_as :johan
			do_put :proposal => "hai, plz merge kthnkxbye"
			
			response.should redirect_to(project_repository_merge_request_path(@project, @target_repository, @merge_request))
			flash[:success].should match(/merge request was updated/i)
			@merge_request.reload.proposal.should == "hai, plz merge kthnkxbye"
		end
		
		it "it re-renders on invalid data, with the target repos list" do
			login_as :johan
			do_put :target_repository => nil
			response.should be_success
			response.should render_template("merge_requests/edit")
			assigns[:repositories].should == [@source_repository]
		end
		
		it "only allows the owner to update" do
			login_as :moe
			do_put
			proc {
				response.should redirect_to(project_repository_path(@project, @target_repository))
				flash[:success].should == nil
				flash[:error].should match(/You're not the owner of this merge request/i)
			}.should_not change(MergeRequest, :count)
		end
	end
	
	describe "#resolve (PUT)" do
		def do_put(data={})
			put :resolve, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param, 
				:id => @merge_request,
				:merge_request => {
					:status => MergeRequest::STATUS_MERGED,
				}.merge(data)
		end
		
		it "requires login" do
			session[:user_id] = nil
			do_put
			response.should redirect_to(new_sessions_path)
		end
		
		it "requires ownership to resoble" do
			login_as :moe
			do_put
			flash[:error].should match(/you're not permitted/i)
			response.should be_redirect
		end
		
		it "updates the status" do
			login_as :johan
			do_put
			flash[:notice].should == "The merge request was marked as merged"
			response.should be_redirect
		end
	end
	
	describe "#get commit_list" do
	  before(:each) do
	    commits = %w(ffc ff0).collect do |sha|
	      m = mock
	      m.stubs(:id).returns(sha)
	      m
      end
	    merge_request = mock
	    merge_request.stubs(:commits_for_selection).returns(commits)
	    MergeRequest.stubs(:new).returns(merge_request)
    end
    
	  it "should render a list of commits that can be merged" do
	    login_as :johan
			get :commit_list, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param,
				:merge_request => {}
    end
  end
	
	describe "#destroy (DELETE)" do
		def do_delete
			delete :destroy, :project_id => @project.to_param, 
				:repository_id => @target_repository.to_param, 
				:id => @merge_request
		end
		
		it "requires login" do
			session[:user_id] = nil
			do_delete
			response.should redirect_to(new_sessions_path)
		end
		
		it "scopes to the source_repository" do
			login_as :johan
			do_delete
			assigns[:merge_request].source_repository.should == @source_repository
		end
		
		it "deletes the record" do
			login_as :johan
			do_delete
			response.should redirect_to(project_repository_path(@project, @target_repository))
			flash[:success].should match(/merge request was retracted/i)
			MergeRequest.find_by_id(@merge_request.id).should == nil
		end
		
		it "only allows the owner to delete" do
			login_as :moe
			do_delete
			proc {
				response.should redirect_to(project_repository_path(@project, @target_repository))
				flash[:success].should == nil
				flash[:error].should match(/You're not the owner of this merge request/i)
			}.should_not change(MergeRequest, :count)
		end
	end

end

describe MergeRequestsController do
	integrate_views
	
	before(:each) do
	  login_as :johan
		@project = projects(:johans)
		@project.owner = groups(:team_thunderbird)
		@project.owner.add_member(users(:johan), Role.committer)
		@repository = repositories(:johans2)
		@mainline_repository = repositories(:johans)
		@merge_request = merge_requests(:moes_to_johans)
	end

	def do_get
		get :show, :project_id => @project.to_param, 
			:repository_id => repositories(:johans).name,
			:id => @merge_request.id
	end

  it "should allow committers to change status" do
		MergeRequest.expects(:find).returns(@merge_request)
		git_stub = stub_everything("Grit", :commit_deltas_from => [])
		[@merge_request.source_repository, @merge_request.target_repository].each do |r|
			r.stubs(:git).returns(git_stub)
		end
		do_get
		response.body.should match(/Update merge request/)			
  end
end