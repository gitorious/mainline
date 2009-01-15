#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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

describe TreesController do
  
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
      response.should redirect_to(project_repository_tree_path(@project, @repository, "somebranch", []))
    end
  end
  
  describe "#show" do
    it "GETs successfully" do
      tree_mock = mock("tree")
      tree_mock.stubs(:id).returns("123")
      @commit_mock = mock("commit")
      @commit_mock.stubs(:tree).returns(tree_mock)
      @git.expects(:commit).with("a"*40).returns(@commit_mock)
      @git.expects(:tree).with(tree_mock.id, ["foo/bar/"]).returns(tree_mock)
      get :show, :project_id => @project.slug, 
        :repository_id => @repository.name, :id => "a"*40, :path => ["foo", "bar"]
        
      response.should be_success
      assigns[:git].should == @git
      assigns[:tree].should == tree_mock
    end
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.expects(:commit).with("a"*40).returns(nil)
      get :show, :project_id => @project.slug, 
        :repository_id => @repository.name, :id => "a"*40, :path => ["foo"]
      
      response.should redirect_to(project_repository_tree_path(@project, @repository, "HEAD", ["foo"]))
    end
  end
  
  describe "#archive" do
    def do_get(opts = {})
      get :archive, {:project_id => @project.slug, 
        :repository_id => @repository.name}.merge(opts)
    end
    
    it "archives the source tree" do
      @git.expects(:commit).returns(true)
      @git.expects(:archive_tar_gz).returns("the data")
      do_get
      response.should be_success
      
      response.headers["type"].should == "application/x-gzip"
      response.headers["Content-Transfer-Encoding"].should == "binary"
    end
  end

end
