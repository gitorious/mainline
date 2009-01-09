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

describe SiteController do

  describe "#index" do    
    it "GETs sucessfully" do
      get :index
      response.should be_success
    end
    
    it "gets a list of the most recent projects" do
      get :index
      assigns[:projects].should == Project.find(:all, :limit => 5, :order => "id desc")
    end
  end
  
  describe "#dashboard" do
    before(:each) do
      login_as :johan
    end
    
    it "GETs successfully" do
      get :dashboard
      response.should be_success
      response.should render_template("site/dashboard")
    end
    
    it "requires login" do
      login_as nil
      get :dashboard
      response.should redirect_to(new_sessions_path)
    end
    
    it "get a list of the current_users projects" do
      get :dashboard
      assigns[:projects].should == [*projects(:johans)]
    end
    
    it "get a list of the current_users repositories, that's not mainline" do
      get :dashboard
      assigns[:repositories].should == [repositories(:johans_moe_clone)]
    end
  end

end


describe SiteController, "in Private Mode" do
  before(:each) do
    GitoriousConfig['public_mode'] = false
  end
  
  after(:each) do
    GitoriousConfig['public_mode'] = true
  end
  
  it "GET / should not show private content in the homepage" do
    get :index
    response.body.should_not match(/Newest projects/)
    response.body.should_not match(/action\=\"\/search"/)
    response.body.should_not match(/Creating a user account/)
    response.body.should_not match(/\/projects/)
    response.body.should_not match(/\/search/)
  end
end