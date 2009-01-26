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

describe Role do
   it "know if it is an admin" do
     roles(:admin).admin?.should == true
     roles(:admin).committer?.should == false
   end
   
   it "know if it is a committer" do
     roles(:committer).committer?.should == true
     roles(:committer).admin?.should == false
   end
   
   it "gets the admin role object" do
     Role.admin.should == roles(:admin)
   end
   
   it "gets the committer object" do
     Role.committer.should == roles(:committer)
   end
end