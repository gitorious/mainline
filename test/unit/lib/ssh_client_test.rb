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


require File.dirname(__FILE__) + '/../../test_helper'

class SSHClientTest < ActiveSupport::TestCase

  def setup
    @strainer = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'").parse!
    @real_path = "abc/123/defg.git"
    @full_real_path = File.join(GitoriousConfig["repository_base_path"], @real_path)
    @ok_stub = stub("ok response mock", :body => "#{@real_path}")
    @not_ok_stub = stub("ok response mock", :body => "nil")
  end
  
  should "parse the project name from the passed in Strainer" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    assert_equal "foo", client.project_name
  end

  should "parse the repository name from the passed in Strainer" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    assert_equal "bar", client.repository_name
  end
    
  context "namespacing" do
    setup do
      @team_strainer = Gitorious::SSH::Strainer.new("git-upload-pack '+foo/bar/baz.git'").parse!
      @user_strainer = Gitorious::SSH::Strainer.new("git-upload-pack '~foo/bar/baz.git'").parse!
    end
    
    should "parse the project name from a team namespaced repo" do
      client = Gitorious::SSH::Client.new(@team_strainer, "johan")
      assert_equal "+foo", client.project_name
      assert_equal "bar/baz", client.repository_name
    end
    
    should "parse the project name from a user namespaced repo" do
      client = Gitorious::SSH::Client.new(@user_strainer, "johan")
      assert_equal "~foo", client.project_name
      assert_equal "bar/baz", client.repository_name
    end
  end
  
  should "sets the username that was passed into it" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    assert_equal "johan", client.user_name
  end
  
  def make_request(path)
    request = ActionController::TestRequest.new
    request.request_uri = path
    request
  end
  
  
  should 'ask for the real path' do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    exp_path = "/foo/bar/writable_by?username=johan"
    assert_equal exp_path, client.writable_by_query_path

    request = make_request(client.writable_by_query_path)
    assert_equal RepositoriesController, ActionController::Routing::Routes.recognize(request)
    assert_equal "writable_by", request.symbolized_path_parameters[:action]
    assert_equal "repositories", request.symbolized_path_parameters[:controller]
    assert_equal "foo", request.symbolized_path_parameters[:project_id]
    assert_equal "bar", request.symbolized_path_parameters[:id]
  end
  
  should 'return the correct authentication URL' do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    assert_equal "http://#{GitoriousConfig['gitorious_client_host']}:#{GitoriousConfig['gitorious_client_port']}/foo/bar/writable_by?username=johan", client.writable_by_query_url
  end
  
  
  should "ask gets the real path from the query url" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/real_path") \
      .returns(@ok_stub)
    client.expects(:connection).once.returns(connection_stub)
    File.expects(:exist?).with(@full_real_path).returns(true)
    assert_equal @full_real_path, client.real_path
  end
  
  should 'raise if the pre-receive hook is not executable' do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    client.stubs(:real_path).returns("/tmp/foo.git")
    File.expects(:"exist?").with("/tmp/foo.git/hooks/pre-receive").returns(true)
    File.expects(:"symlink?").with("/tmp/foo.git/hooks/pre-receive").returns(false)
    File.expects(:"executable?").with("/tmp/foo.git/hooks/pre-receive").returns(false)
    assert !client.pre_receive_hook_exists?
  end
  
  should "raises if the real path doesn't exist" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/real_path") \
      .returns(@ok_stub)
    client.expects(:connection).once.returns(connection_stub)
    File.expects(:exist?).with(@full_real_path).returns(false)
    assert_raises(Gitorious::SSH::AccessDeniedError) do
      client.real_path
    end
  end
  
  should "raises if the real path isn't returned" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/real_path") \
      .returns(@not_ok_stub)
    client.expects(:connection).once.returns(connection_stub)
    assert_raises(Gitorious::SSH::AccessDeniedError) do
      client.real_path
    end
  end
  
  should "returns the command we can safely execute with git-shell" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    connection_stub = stub_everything("connection_stub")
    connection_stub.expects(:get) \
      .with("/foo/bar/real_path") \
      .returns(@ok_stub)
    client.expects(:connection).once.returns(connection_stub)
    File.expects(:exist?).with(@full_real_path).returns(true)
    assert_equal "git-upload-pack '#{@full_real_path}'", client.to_git_shell_argument
  end
  
end
