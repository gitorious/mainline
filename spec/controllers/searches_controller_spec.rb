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

describe SearchesController do

  describe "#show" do
    it "searches for the given query" do
      searcher = mock("ultrasphinx search")
      Ultrasphinx::Search.expects(:new).with({
        :query => "foo", :page => 1
      }).returns(searcher)
      searcher.expects(:run)
      searcher.expects(:results).returns(results = mock("results"))
      
      get :show, :q => "foo"
      assigns["search"].should == searcher
      assigns["results"].should == results
    end
    
    it "doesnt search if there's no :q param" do
      Ultrasphinx::Search.expects(:new).never
      get :show, :q => ""
      assigns["search"].should == nil
      assigns["results"].should == nil
    end
  end

end
