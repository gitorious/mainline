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

describe Participation do
  
  it "should require presence of group_id" do
    p = new_participation
    p.group = nil
    p.valid?
    p.should have(1).errors_on(:group_id)
  end
  
  it "should require presence of repository" do
    p = new_participation
    p.repository = nil
    p.valid?
    p.should have(1).errors_on(:repository_id)
  end
  
  it "should have a creator" do
    participation = new_participation
    participation.creator.should == users(:johan)
  end
  
  def new_participation(opts = {})
    Participation.new({
      :repository => repositories(:johans),
      :group => groups(:team_thunderbird),
      :creator => users(:johan)
    }.merge(opts))
  end
  
end