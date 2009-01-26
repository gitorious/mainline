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

describe Group do
  describe "members" do
    it "knows if a user is a member" do
      groups(:johans_core).member?(users(:johan)).should == true
      groups(:johans_core).member?(users(:mike)).should == false
    end
    
    it "know the role of a member" do
      groups(:johans_core).role_of_user(users(:mike)).should == nil
      groups(:johans_core).role_of_user(users(:johan)).should == roles(:admin)
      groups(:johans_core).admin?(users(:mike)).should == false
      groups(:johans_core).admin?(users(:johan)).should == true
      
      groups(:johans_core).committer?(users(:mike)).should == false
      groups(:johans_core).committer?(users(:johan)).should == true
    end
  end
end