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

describe BlobsController do
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
  
  describe "#show" do
    it "gets the blob data for the sha provided" do
      blob_mock = mock("blob")
      blob_mock.stub!(:contents).and_return([blob_mock]) #meh
      blob_mock.stub!(:data).and_return("blob contents")
      commit_stub = mock("commit")
      commit_stub.stub!(:id).and_return("a"*40)
      commit_stub.stub!(:tree).and_return(commit_stub)
      @git.should_receive(:commit).and_return(commit_stub)
      @git.should_receive(:tree).and_return(blob_mock)
      
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => []}
      
      response.should be_success
      assigns[:git].should == @git
      assigns[:blob].should == blob_mock
    end 
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.should_receive(:commit).with("a"*40).and_return(nil)
      get :show, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => ["foo.rb"]}
      
      response.should redirect_to(project_repository_blob_path(@project, @repository, "HEAD", ["foo.rb"]))
    end   
  end
  
  describe "#raw" do
    it "gets the blob data from the sha and renders it as text/plain" do
      blob_mock = mock("blob")
      blob_mock.stub!(:contents).and_return([blob_mock]) #meh
      blob_mock.should_receive(:data).and_return("blabla")
      blob_mock.should_receive(:size).and_return(200.kilobytes)
      blob_mock.should_receive(:mime_type).and_return("text/plain")
      commit_stub = mock("commit")
      commit_stub.stub!(:id).and_return("a"*40)
      commit_stub.stub!(:tree).and_return(commit_stub)
      @git.should_receive(:commit).and_return(commit_stub)
      @git.should_receive(:tree).and_return(blob_mock)
      
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => []}
      
      response.should be_success
      assigns[:git].should == @git
      assigns[:blob].should == blob_mock
      response.body.should == "blabla"
      response.content_type.should == "text/plain"
    end
    
    it "redirects to HEAD if provided sha was not found (backwards compat)" do
      @git.should_receive(:commit).with("a"*40).and_return(nil)
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => ["foo.rb"]}
      
      response.should redirect_to(project_repository_raw_blob_path(@project, @repository, "HEAD", ["foo.rb"]))
    end
    
    it "redirects if blob is too big" do
      blob_mock = mock("blob")
      blob_mock.stub!(:contents).and_return([blob_mock]) #meh
      blob_mock.should_receive(:size).and_return(501.kilobytes)
      commit_stub = mock("commit")
      commit_stub.stub!(:id).and_return("a"*40)
      commit_stub.stub!(:tree).and_return(commit_stub)
      @git.should_receive(:commit).and_return(commit_stub)
      @git.should_receive(:tree).and_return(blob_mock)
      
      get :raw, {:project_id => @project.slug, 
          :repository_id => @repository.name, :id => "a"*40, :path => []}
          
      response.should redirect_to(project_repository_path(@project, @repository))
    end
  end

end
