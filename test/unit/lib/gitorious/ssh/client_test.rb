# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
require "gitorious/ssh/client"

class SSHClientTest < ActiveSupport::TestCase
  def setup
    @strainer = Gitorious::SSH::Strainer.new("git-upload-pack 'foo/bar.git'").parse!
    @real_path = "abc/123/defg.git"
    @full_real_path = File.join(RepositoryRoot.default_base_path, @real_path)
    @ok_stub = stub("ok response mock",
      :body => "real_path:#{@real_path}\nforce_pushing_denied:false")
    @not_ok_stub = stub("ok response mock", :body => "nil")
  end

  def make_request(path)
    request = ActionController::TestRequest.new
    request.request_uri = path
    request
  end

  should "ask for the real path" do
    client = Gitorious::SSH::Client.new(@strainer, "johan")
    exp_path = "/foo/bar/writable_by?username=johan"
    assert_equal exp_path, client.writable_by_query_path

    request = make_request(client.writable_by_query_path)
    uri = request.env["REQUEST_URI"]

    route = Rails.application.routes.recognize_path(uri)
    assert_equal "repositories", route[:controller]
    assert_equal "writable_by", route[:action]
    assert_equal "foo", route[:project_id]
    assert_equal "bar", route[:id]
  end
end
