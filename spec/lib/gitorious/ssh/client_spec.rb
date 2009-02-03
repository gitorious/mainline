#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
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

require File.dirname(__FILE__) + '/../../../spec_helper'

describe Gitorious::SSH::Client do
  
  before(:each) do
    @strainer = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'").parse!
    @real_path = "abc/123/defg.git"
    @full_real_path = File.join(GitoriousConfig["repository_base_path"], @real_path)
    @ok_stub = stub("ok response mock", :body => "true #{@real_path}")
    @not_ok_stub = stub("ok response mock", :body => "false nil")
  end
  
  it "parses the project name from the passed in Strainer" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.project_name.should == "foo"
  end
  
  it "parses the repository name from the passed in Strainer" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.repository_name.should == "bar"
  end
  
  it "sets the username that was passed into it" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.user_name.should == "johan"
  end
  
  def make_request(path)
    request = ActionController::TestRequest.new
    request.request_uri = path
    request
  end
  
  it "has a query_url" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    # exp_url = "/projects/foo/repos/bar/writable_by?username=johan"
    # client.query_url.should == exp_url
    
    request = make_request(client.query_url)
    ActionController::Routing::Routes.recognize(request).should == RepositoriesController
    # check against the actual routes
    request.symbolized_path_parameters[:action].should == "writable_by"
    request.symbolized_path_parameters[:controller].should == "repositories"
    request.symbolized_path_parameters[:project_id].should == "foo"
    request.symbolized_path_parameters[:id].should == "bar"
  end
  
  it "asks the server if a user has permission" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/writable_by?username=johan") \
      .returns(@ok_stub)
    client.expects(:connection).returns(connection_stub)

    client.writable_by_user?.should == true
  end
  
  it "returns false if a user doesn't have write permissions" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/writable_by?username=johan") \
      .returns(@not_ok_stub)
    client.expects(:connection).returns(connection_stub)

    client.writable_by_user?.should == false
  end
  
  it "assure_user_can_write! raises if a user doesn't have write permissions" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.expects(:writable_by_user?).returns(false)

    proc {
      client.assure_user_can_write!
    }.should raise_error(Gitorious::SSH::AccessDeniedError)
  end
  
  it "assure_user_can_write! doesn't raise if a  user have write permissions" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.expects(:writable_by_user?).returns(true)

    proc {
      client.assure_user_can_write!
    }.should_not raise_error(Gitorious::SSH::AccessDeniedError)
  end
  
  it "ask gets the real path from the query url" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/writable_by?username=johan") \
      .returns(@ok_stub)
    client.expects(:connection).once.returns(connection_stub)
    File.expects(:exist?).with(@full_real_path).returns(true)
    client.real_path.should == @full_real_path
  end
  
  it "raises if the real path doesn't exist" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/writable_by?username=johan") \
      .returns(@ok_stub)
    client.expects(:connection).once.returns(connection_stub)
    File.expects(:exist?).with(@full_real_path).returns(false)
    proc {
      client.real_path
    }.should raise_error(Gitorious::SSH::AccessDeniedError)
  end
  
  it "raises if the real path isn't returned" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/writable_by?username=johan") \
      .returns(@not_ok_stub)
    client.expects(:connection).once.returns(connection_stub)
    proc {
      client.real_path
    }.should raise_error(Gitorious::SSH::AccessDeniedError)
  end
  
  it "returns the command we can safely execute with git-shell" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/writable_by?username=johan") \
      .returns(@ok_stub)
    client.expects(:connection).once.returns(connection_stub)
    File.expects(:exist?).with(@full_real_path).returns(true)
    client.to_git_shell_argument.should == "git-upload-pack '#{@full_real_path}'"
  end
  
end