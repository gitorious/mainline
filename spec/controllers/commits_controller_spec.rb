#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

describe CommitsController do  
  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
    @repository.stubs(:full_repository_path).returns(repo_path)
    
    Project.expects(:find_by_slug!).with(@project.slug) \
      .returns(@project)
    @project.repositories.expects(:find_by_name!) \
      .with(@repository.name).returns(@repository)
    @repository.stubs(:has_commits?).returns(true)
    
    @git = stub_everything("Grit mock")
    @repository.stubs(:git).returns(@git)
    @head = mock("master branch")
    @head.stubs(:name).returns("master")
    @repository.stubs(:head_candidate).returns(@head)
  end
  
  describe "#index" do
    it "redirects to the master head, if not :id given" do
      head = mock("a branch")
      head.stubs(:name).returns("somebranch")
      @repository.expects(:head_candidate).returns(head)
      
      get :index, :project_id => @project.slug, :repository_id => @repository.name
      response.should redirect_to(project_repository_log_path(@project, @repository, "somebranch"))
    end
    
    it "redirects if repository doens't have any commits" do
      @repository.expects(:has_commits?).returns(false)
      get :index, :project_id => @project.slug, :repository_id => @repository.name
      response.should be_redirect
      flash[:notice].should match(/repository doesn't have any commits yet/)
    end
  end

  describe "#show" do    
    before(:each) do
      @commit_mock = stub("commit", :id => 1)
      @diff_mock = mock("diff mock")
      @commit_mock.expects(:diffs).returns(@diff_mock)
      @git.expects(:commit).with("a"*40).returns(@commit_mock)
    end
    
    def do_get(opts={})
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40}.merge(opts)
    end
    
    it "gets the commit data" do
      do_get
      response.should be_success
      assigns[:git].should == @git
      assigns[:commit].should == @commit_mock
      assigns[:diffs].should == @diff_mock
    end
    
    it "gets the comments for the commit" do
      do_get
      assigns[:comment_count].should == 0
    end
    
    it "defaults to 'inline' diffmode" do
      do_get
      assigns[:diffmode].should == "inline"
    end
    
    it "sets sidebyside diffmode" do
      do_get(:diffmode => "sidebyside")
      assigns[:diffmode].should == "sidebyside"
    end
  end
end
