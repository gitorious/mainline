#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

describe ApplicationHelper do
  
  include ApplicationHelper
  
  it "renders a message if an object is not ready?" do
    repos = repositories(:johans)
    helper.build_notice_for(repos).should include("This repository is being created")
  end
  
  it "renders block if object is ready" do
    obj = mock("any given object")
    obj.stub!(:ready?).and_return(true)
    helper.render_if_ready(obj) do
      "moo"
    end.should == "moo"
  end
  
  it "renders block if object is ready" do
    obj = mock("any given object")
    obj.stub!(:ready?).and_return(false)
    helper.output_buffer = "" # damn you RSpec!
    helper.render_if_ready(obj) do
      "moo"
    end
    helper.output_buffer.should_not == "moo"
    helper.output_buffer.should match(/is being created/)
  end
  
  it "gives us the domain of a full url" do
    helper.base_url("http://foo.com").should == "foo.com"
    helper.base_url("http://www.foo.com").should == "www.foo.com"
    helper.base_url("http://foo.bar.baz.com").should == "foo.bar.baz.com"
    helper.base_url("http://foo.com/").should == "foo.com"
    helper.base_url("http://foo.com/bar/baz").should == "foo.com"
  end
  
  it "generates a valid gravatar url" do
    email = "someone@myemail.com";
    url = gravatar_url_for(email)
    
    helper.base_url(url).should == "www.gravatar.com"
    url.include?(Digest::MD5.hexdigest(email)).should == true
    url.include?("avatar.php?").should == true
  end
  
    
  it "should generate a blank commit graph url if the graph isn't there" do
    File.should_receive(:exist?).and_return(false)
    url = helper.commit_graph_tag(repositories(:johans))    
    url.should == nil
  end
  
  it "should generate a blank url for commit graph by author if the graph isn't there" do
    File.should_receive(:exist?).and_return(false)
    
    url = helper.commit_graph_by_author_tag(repositories(:johans))
    url.should == nil
  end
end
