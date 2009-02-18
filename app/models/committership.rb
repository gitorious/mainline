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

class Committership < ActiveRecord::Base
  belongs_to :committer, :polymorphic => true
  belongs_to :repository
  belongs_to :creator, :class_name => 'User'
  
  validates_presence_of :committer_id, :committer_type, :repository_id
  
  def breadcrumb_parent
    Breadcrumb::Committerships.new(repository)
  end
  
  def title
    new_record? ? "New commit team" : "Commit team"
  end
  
  # returns all the users in this committership, eg if it's a group it'll 
  # return an array of the group members, otherwise a single-member array of
  # the user
  def members
    case committer
    when Group
      committer.members
    else
      [committer]
    end
  end
end
