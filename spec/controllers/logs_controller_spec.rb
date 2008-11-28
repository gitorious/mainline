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

describe LogsController do

  before(:each) do
    @project = projects(:johans)
    @repository = @project.repositories.first
    @repository.stub!(:full_repository_path).and_return(repo_path)

    Project.should_receive(:find_by_slug!).with(@project.slug) \
      .and_return(@project)
    @project.repositories.should_receive(:find_by_name!) \
      .with(@repository.name).and_return(@repository)
    @repository.stub!(:has_commits?).and_return(true)

    @git = mock("Grit mock", :null_object => true)
    @repository.stub!(:git).and_return(@git)
    @head = mock("master branch")
    @head.stub!(:name).and_return("master")
    @repository.stub!(:head_candidate).and_return(@head)
  end
  
  describe "#index" do
    it "redirects to the master head, if not :id given" do
      head = mock("a branch")
      head.stub!(:name).and_return("somebranch")
      @repository.should_receive(:head_candidate).and_return(head)

      get :index, :project_id => @project.slug, :repository_id => @repository.name
      response.should redirect_to(project_repository_log_path(@project, @repository, "somebranch"))
    end
  end

  describe "#show" do
    def do_get(opts = {})
      get :show, {:project_id => @project.slug, 
        :repository_id => @repository.name, :page => nil, :id => "master"}.merge(opts)
    end

    it "GETs page 1 successfully" do
      @git.should_receive(:commits).with("master", 30, 0).and_return([mock("commits")])
      do_get
    end

    it "GETs page 3 successfully" do
      @git.should_receive(:commits).with("master", 30, 60).and_return([mock("commits")])
      do_get(:page => 3)
    end

    it "GETs the commits successfully" do
      commits = [mock("commits")]
      @git.should_receive(:commits).with("master", 30, 0).and_return(commits)
      do_get
      response.should be_success
      assigns[:git].should == @git
      assigns[:commits].should == commits
    end
    
    
    describe "atom feed" do
      integrate_views
      
      it "has a proper id in the atom feed" do
        #(repo, id, parents, tree, author, authored_date, committer, committed_date, message)
        commit = Grit::Commit.new(mock("repo"), "mycommitid", [], mock("tree", :null_object => true), 
                      mock("author", :null_object => true), Time.now, 
                      mock("comitter", :null_object => true), Time.now, 
                      "my commit message".split(" "))
        @git.should_receive(:commits).and_return([commit])
        commit.stub!(:stats).and_return(mock("stats", :null_object => true))
        
        get :feed, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "master", :format => "atom"}
        response.body.should include(%Q{<id>tag:test.host,2005:Grit::Commit/mycommitid</id>})
      end
    end
  end

end
