#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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

describe PagesController do

  before(:each) do
    @project = projects(:johans)
    @repo = @project.wiki_repository
    #authorize_as :johan
  end
  
  describe "index" do
    it "redirects to the Home page" do
      get :index, :project_id => @project.to_param
      response.should redirect_to(project_page_path(@project, "Home"))
    end
  end

  # FUCK RSPEC MOCKS
  # describe "show" do
  #   it "redirects to edit if the page is new" do
  #     page_stub = mock("page stub")
  #     page_stub.should_receive(:new?).and_return(true)
  #     @project.wiki_repository.should_receive(:git).and_return(mock("git"))
  #     Page.should_receive(:find).and_return(page_stub)
  #     
  #     get :show, :project_id => @project.to_param, :id => "Home"
  #     puts response.body
  #     response.should redirect_to(edit_project_page_path(@project, "Home"))
  #   end
  # end
  
end
