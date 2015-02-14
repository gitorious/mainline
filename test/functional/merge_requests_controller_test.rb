# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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

class MergeRequestsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context
    TestCommit = Struct.new(:id, :name, :message) do
      def id_abbrev
        id.to_s[0..6]
      end
      def committer
        name
      end
      def time
        1.year.ago
      end
      def short_message
        message
      end
    end

  def setup
    setup_ssl_from_config
    @project = projects(:johans)
    @project.update_attribute(:merge_requests_need_signoff, false)
    MergeRequestStatus.create_defaults_for_project(@project)
    grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(grit)
    @source_repository = repositories(:johans2)
    @target_repository = repositories(:johans)
    @merge_request = merge_requests(:moes_to_johans_open)
    @merge_request.stubs(:commit_merged?).returns(true)
    version = @merge_request.create_new_version('ff')
    MergeRequestVersion.any_instance.stubs(:affected_commits).returns([])
    @merge_request.versions << version
    version.stubs(:merge_request).returns(@merge_request)


    commit_stub = TestCommit.new("fff", "This is great")
    MergeRequest.any_instance.stubs(:commits_for_selection).returns([commit_stub])

    assert_not_nil @merge_request.versions.last
  end

  context "#index (GET)" do
    should "not require login" do
      session[:user_id] = nil
      get :index, params
      assert_response :success
    end

    should "gets all the merge requests in the repository" do
      %w(html xml).each do |format|
        get :index, params(:format => format)
        assert_equal @target_repository.merge_requests, assigns(:open_merge_requests)
      end
    end

    should "filter on status" do
      @merge_request.update_attribute(:status_tag, "merged")
      get :index, params(:status => "merged")
      assert_response :success
      assert_equal [@merge_request], assigns(:open_merge_requests)
    end

    context "paginating merge requests" do
      setup do
        @params = params
      end

      should_scope_pagination_to(:index, MergeRequest, "merge requests")
    end
  end

  context "#show (GET)" do
    should "not require login" do
      session[:user_id] = nil
      MergeRequest.expects(:find_by_sequence_number!).returns(@merge_request)
      stub_commits(@merge_request)
      [@merge_request.source_repository, @merge_request.target_repository].each do |r|
        r.stubs(:git).returns(stub_everything("Git"))
      end

      get :show, mr_params
      assert_response :success
      assert_select "h3", :content => "Add a new comment:"
    end

    should "get a list of the commits to be merged" do
      %w(html patch xml).each do |format|
        MergeRequest.expects(:find_by_sequence_number!).returns(@merge_request)
        stub_commits(@merge_request)

        get :show, mr_params(:format => format)
        assert_response :success
      end
    end

    should "not display a comment change field unless the current user can change the MR" do
      login_as :moe
      assert !can_resolve_merge_request?(users(:moe), @merge_request)

      get :show, mr_params
      assert_response :success
      assert_select "select#comment_state", false
    end

    context "Git timeouts" do
      setup do
        MergeRequest.any_instance.stubs(:commits_to_be_merged).raises(Grit::Git::GitTimeout)
        MergeRequestVersion.any_instance.stubs(:affected_commits).raises(Grit::Git::GitTimeout)
      end

      should "catch timeouts and render metadata only" do
        get :show, mr_params

        assert_response :success
      end
    end

    should "display 'how to merge' help with correct branch" do
      stub_commits(@merge_request)
      @merge_request.sequence_number = 399
      @merge_request.target_branch = "superfly-feature"
      @merge_request.save

      get :show, mr_params

      assert_response 200
      assert @response.body.include?("git merge merge-requests/399")
      assert @response.body.include?("git push origin superfly-feature")
    end
  end

  context "#new (GET)" do
    setup do
      Grit::Repo.any_instance.stubs(:heads).returns([])
    end

    should "requires login" do
      session[:user_id] = nil
      get :new, params
      assert_redirected_to(new_sessions_path)
    end

    should "get new successfully" do
      login_as :johan
      get :new, params
      assert_response :success
    end

    should "assign to @project even when accessed through a user" do
      johan = users(:johan)
      login_as :johan
      @source_repository.owner = johan
      @source_repository.save!
      get :new, params(:user_id => johan.to_param)
      assert_response :success
    end

    should "assign the new merge_requests' source_repository" do
      login_as :johan
      get :new, params(:repository_id => @source_repository.to_param)
      assert_equal @source_repository, assigns(:merge_request).source_repository
    end

    should "get a list of possible target clones" do
      login_as :johan
      get :new, params(:repository_id => @source_repository.to_param)
      assert_equal [repositories(:johans)], assigns(:repositories)
    end

    should "not suggest merging with a non-MR repo" do
      cmd = CloneRepositoryCommand.new(MessageHub.new, @source_repository, users(:johan))
      clone = cmd.execute(cmd.build(CloneRepositoryInput.new(:merge_requests_enabled => false)))
      login_as :johan

      get :new, params(:repository_id => @source_repository.to_param)
      assert !assigns(:repositories).include?(clone)
    end

    should "suggest the parent of the source repo as target" do
      login_as :johan
      get :new, params(:repository_id => @source_repository.to_param)
      assert_equal @source_repository.parent.id, assigns(:merge_request).target_repository_id
    end
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
      @project.update_attribute(:merge_requests_need_signoff, true)
      @controller.expects(:obtain_oauth_request_token).returns(mock_token)
      assert_difference("MergeRequest.count") do
        do_post
        assert_response :redirect
        result = assigns(:merge_request)
        assert_equal(terms_accepted_project_repository_merge_request_path(@source_repository.project, @target_repository, result), session[:return_to])
      end
    end

    should "not require off-site signoff of terms unless the repository needs it" do
      login_as(:johan)
      post :create, :project_id => @project.to_param,
      :repository_id => @target_repository.to_param, :merge_request => {
        :target_repository_id => @source_repository.id,
        :ending_commit => "6823e6622e1da9751c87380ff01a1db1",
        :summary => "some changes"
      }
      result = assigns(:merge_request)
      assert !result.acceptance_of_terms_required?
      assert result.open?
      assert_match(/sent a merge request to "#{@source_repository.name}"/i, flash[:success])
    end

    should "create an event when the request does not require signof" do
      login_as :johan
      assert_difference("@project.events.count", 1) do
        post :create, :project_id => @project.to_param,
        :repository_id => @target_repository.to_param, :merge_request => {
          :target_repository_id => @source_repository.id,
          :ending_commit => "6823e6622e1da9751c87380ff01a1db1",
          :summary => "some changes"
        }
      end
    end

    should "it re-renders on invalid data, with the target repos list" do
      login_as :johan
      MergeRequest.any_instance.stubs(:save).returns(false)
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
  end

  context "Terms accepted (GET)" do
    setup do
      @merge_request = @source_repository.proposed_merge_requests.new({ :summary => "plz merge",
                                                                        :proposal => "Would like this to be merged",
                                                                        :user => users(:johan),
                                                                        :ending_commit => "6823e6622e1da9751c87380ff01a1db1",
                                                                        :target_repository => @target_repository,
                                                                        :summary => "foo" })
      assert @merge_request.save_with_next_sequence_number
      @merge_request.stubs(:commits_to_be_merged).returns([])
      MergeRequest.stubs(:find_by_sequence_number!).returns(@merge_request)
      login_as :johan
    end

    should "set the status to open when done authenticating thru OAuth" do
      @merge_request.stubs(:valid_oauth_credentials?).returns(true)
      @merge_request.expects(:terms_accepted)

      get :terms_accepted, mr_params
      assert_response :redirect
    end

    should "not set the status to open if OAuth authentication has not been performed" do
      @merge_request.stubs(:valid_oauth_credentials?).returns(false)

      get :terms_accepted, mr_params
      assert_response :redirect
      assert !@merge_request.open?
    end
  end

  context "#edit (GET)" do
    should "requires login" do
      session[:user_id] = nil
      do_edit_get
      assert_redirected_to(new_sessions_path)
    end

    should "requires ownership to edit" do
      login_as :moe
      do_edit_get
      assert_match(/you are not the owner/i, flash[:error])
      assert_response :redirect
    end

    should "is successfull" do
      login_as :johan
      do_edit_get
      assert_response :success
    end

    should "gets a list of possible target clones" do
      login_as :johan
      do_edit_get
      assert_equal [@source_repository], assigns(:repositories)
    end
  end

  context "commit_merged (GET)" do
    setup do
      @merge_request.stubs(:commit_merged?).with("ffc").returns(false)
      @merge_request.stubs(:commit_merged?).with("ffo").returns(true)
      MergeRequest.stubs(:find_by_sequence_number!).returns(@merge_request)
    end

    should "return false if the given commit has not been merged" do
      do_commit_status_get(:commit_id => "ff0")
      assert_response :success
      assert_equal "true", @response.body
    end

    should "return true if the given commit has been merged" do
      do_commit_status_get(:commit_id => "ffc")
      assert_response :success
      assert_equal "false", @response.body
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
      assert_match(/you are not the owner/i, flash[:error])
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
      MergeRequest.any_instance.stubs(:save).returns(false)
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
        assert_match(/You are not the owner of this merge request/i, flash[:error])
      end
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
        m.stubs(:time).returns(3.days.ago)
        m
      end
      merge_request = MergeRequest.new
      merge_request.stubs(:commits_for_selection).returns(@commits)
      MergeRequest.expects(:new).returns(merge_request)
    end

    should "render a list of commits that can be merged" do
      login_as :johan
      post :commit_list, params(:merge_request => {})
      assert_equal @commits, assigns(:commits)
    end
  end

  context "GET #target_branches" do
    should "retrive a list of the target repository branches" do
      Gitorious::Configuration.override("enable_private_repositories" => false) do
        grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
        MergeRequest.any_instance.expects(:target_branches_for_selection).returns(grit.branches)

        login_as :johan
        post :target_branches, mr_params(:merge_request => {
                                           :target_repository_id => repositories(:johans).id
                                         })
        assert_response :success
        assert_equal grit.branches, assigns(:target_branches)
      end
    end
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

    should "soft-delete the record" do
      login_as :johan
      assert_difference("@target_repository.open_merge_requests.count", -1) do
        do_delete
      end
      assert_redirected_to(project_repository_path(@project, @target_repository))
      assert_match(/merge request was retracted/i, flash[:success])
    end

    should "only allows the owner to delete" do
      login_as :moe
      do_delete
      assert_no_difference("MergeRequest.count") do
        assert_redirected_to(project_repository_path(@project, @target_repository))
        assert_equal nil, flash[:success]
        assert_match(/You are not the owner of this merge request/i, flash[:error])
      end
    end
  end

  context "Redirection from the outside" do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
    end

    should "redirect to the correct URL when supplying only an id" do
      get :direct_access, :id => @merge_request.id
      assert_redirected_to({ :action => "show",
                             :project_id => @merge_request.target_repository.project,
                             :repository_id => @merge_request.target_repository,
                             :id => @merge_request.to_param})
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
      stub_commits(@merge_request)
      MergeRequest.stubs(:find_by_sequence_number!).returns(@merge_request)
    end

    should "disallow unauthenticated users from listing merge requests" do
      get :index, params
      assert_response 403
    end

    should "allow authenticated users to list merge requests" do
      MergeRequest.unstub(:find_by_sequence_number!)
      login_as :johan
      get :index, params
      assert_response :success
    end

    should "disallow unauthenticated users from listing commits" do
      login_as :mike
      post :commit_list, params(:merge_request => {})
      assert_response 403
    end

    should "allow authenticated users to list commits" do
      login_as :johan
      post :commit_list, params(:merge_request => {})
      assert_response 200
    end

    should "disallow unauthenticated users from viewing commit status" do
      @merge_request.stubs(:commit_merged?).with("ffo").returns(true)

      do_commit_status_get(:commit_id => "ff0")
      assert_response 403
    end

    should "allow authenticated users to view commit status" do
      login_as :johan
      @merge_request.stubs(:commit_merged?).with("ffo").returns(true)

      do_commit_status_get(:commit_id => "ff0")
      assert_response :success
    end

    context "GET #target_branches" do
      setup do
        grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
        MergeRequest.any_instance.stubs(:target_branches_for_selection).returns(grit.branches)
        @params = mr_params(:merge_request => { :target_repository_id => repositories(:johans).id })
      end

      should "disallow unauthenticated users" do
        login_as :mike
        post :target_branches, @params
        assert_response 403
      end

      should "allow authenticated users" do
        login_as :johan
        post :target_branches, @params
        assert_response 200
      end
    end

    context "#show (GET)" do
      should "disallow unauthenticated users" do
        get :show, mr_params
        assert_response 403
      end

      should "allow authenticated users" do
        login_as :johan
        get :show, mr_params
        assert_response 200
      end
    end

    should "disallows unauthenticated user from opening new MR" do
      login_as :mike
      get :new, params
      assert_response 403
    end

    should "allows authenticated user to open new MR" do
      login_as :johan
      get :new, params
      assert_response :success
    end

    should "disallow unauthenticated user from accepting terms" do
      login_as :mike
      get :terms_accepted, mr_params
      assert_response 403
    end

    should "allow authenticated user to accept terms" do
      login_as :johan
      @merge_request.stubs(:valid_oauth_credentials?).returns(true)
      @merge_request.expects(:terms_accepted)

      get :terms_accepted, mr_params
      assert_response :redirect
    end

    should "disallow unauthenticated user from creating MR" do
      login_as :mike
      post :create, params(:merge_request => {
        :target_repository_id => @source_repository.id,
        :ending_commit => "6823e6622e1da9751c87380ff01a1db1",
        :summary => "some changes"
      })

      assert_response 403
    end

    should "allow authenticated user to create MR" do
      login_as :johan
      post :create, params(:merge_request => {
        :target_repository_id => @source_repository.id,
        :ending_commit => "6823e6622e1da9751c87380ff01a1db1",
        :summary => "some changes"
      })

      assert_response 302
    end

    should "disallow unauthenticated users direct access" do
      get :direct_access, :id => @merge_request.id
      assert_response 403
    end
  end

  context "With private repositories" do
    setup do
      enable_private_repositories(@target_repository)
      @project.content_memberships.delete_all
      stub_commits(@merge_request)
      MergeRequest.stubs(:find_by_sequence_number!).returns(@merge_request)
    end

    should "disallow unauthenticated users from listing merge requests" do
      get :index, params
      assert_response 403
    end

    should "allow authenticated users to list merge requests" do
      MergeRequest.unstub(:find_by_sequence_number!)
      login_as :johan
      get :index, params
      assert_response :success
    end

    should "disallow unauthenticated users from listing commits" do
      login_as :mike
      post :commit_list, params(:merge_request => {})
      assert_response 403
    end

    should "allow authenticated users to list commits" do
      login_as :johan
      post :commit_list, params(:merge_request => {})
      assert_response 200
    end

    should "disallow unauthenticated users from viewing commit status" do
      @merge_request.stubs(:commit_merged?).with("ffo").returns(true)

      do_commit_status_get(:commit_id => "ff0")
      assert_response 403
    end

    should "allow authenticated users to view commit status" do
      login_as :johan
      @merge_request.stubs(:commit_merged?).with("ffo").returns(true)

      do_commit_status_get(:commit_id => "ff0")
      assert_response :success
    end

    context "GET #target_branches" do
      setup do
        grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
        MergeRequest.any_instance.stubs(:target_branches_for_selection).returns(grit.branches)
        @params = mr_params(:merge_request => { :target_repository_id => repositories(:johans).id })
      end

      should "disallow unauthenticated users" do
        login_as :mike
        post :target_branches, @params
        assert_response 403
      end

      should "allow authenticated users" do
        login_as :johan
        post :target_branches, @params
        assert_response 200
      end
    end

    context "#show (GET)" do
      should "disallow unauthenticated users" do
        get :show, mr_params
        assert_response 403
      end

      should "allow authenticated users" do
        login_as :johan
        get :show, mr_params
        assert_response 200
      end
    end

    should "disallows unauthenticated user from opening new MR" do
      login_as :mike
      get :new, params
      assert_response 403
    end

    should "allows authenticated user to open new MR" do
      login_as :johan
      get :new, params
      assert_response :success
    end

    should "disallow unauthenticated user from accepting terms" do
      login_as :mike
      get :terms_accepted, mr_params
      assert_response 403
    end

    should "allow authenticated user to accept terms" do
      login_as :johan
      @merge_request.stubs(:valid_oauth_credentials?).returns(true)
      @merge_request.expects(:terms_accepted)

      get :terms_accepted, mr_params
      assert_response :redirect
    end

    should "disallow unauthenticated user from creating MR" do
      login_as :mike
      post :create, params(:merge_request => {
        :target_repository_id => @source_repository.id,
        :ending_commit => "6823e6622e1da9751c87380ff01a1db1",
        :summary => "some changes"
      })

      assert_response 403
    end

    should "allow authenticated user to create MR" do
      login_as :johan
      post :create, params(:merge_request => {
        :target_repository_id => @source_repository.id,
        :ending_commit => "6823e6622e1da9751c87380ff01a1db1",
        :summary => "some changes"
      })

      assert_response 302
    end

    should "disallow unauthenticated users direct access" do
      get :direct_access, :id => @merge_request.id
      assert_response 403
    end
  end

  private
  def params(data = {})
    { :project_id => @project.to_param,
      :repository_id => @target_repository.to_param }.merge(data)
  end

  def mr_params(data = {})
    params(:id => @merge_request.to_param).merge(data)
  end

  def stub_commits(merge_request)
    commits = ["9dbb89110fc45362fc4dc3f60d960381",
               "6823e6622e1da9751c87380ff01a1db1",
               "526fa6c0b3182116d8ca2dc80dedeafb",
               "286e8afb9576366a2a43b12b94738f07"].collect do |sha|
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

  def do_post(data={})
    post :create, params(:repository_id => @source_repository.to_param, :merge_request => {
      :target_repository_id => @target_repository.id,
      :ending_commit => "6823e6622e1da9751c87380ff01a1db1",
      :summary => "some changes to be merged"
    }.merge(data))
  end

  def do_edit_get
    get :edit, mr_params
  end

  def do_put(data={})
    put :update, mr_params(:merge_request => {
      :target_repository_id => @target_repository.id,
    }.merge(data))
  end

  def do_delete
    delete :destroy, mr_params
  end

  def do_commit_status_get(data = {})
    get :commit_status, mr_params(data)
  end
end
