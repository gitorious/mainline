# encoding: utf-8
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


require File.dirname(__FILE__) + '/../test_helper'

class ParticipationTest < ActiveSupport::TestCase
  
  should_validate_presence_of :repository_id, :group_id
  
  should " have a creator" do
    participation = new_participation
    assert_equal users(:johan), participation.creator
  end
  
  def new_participation(opts = {})
    Participation.new({
      :repository => repositories(:johans),
      :group => groups(:team_thunderbird),
      :creator => users(:johan)
    }.merge(opts))
  end
  
end
