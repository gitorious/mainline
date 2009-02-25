#--
#   Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
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

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, :polymorphic => true
  belongs_to :project
  has_many   :events, :as => :target, :dependent => :destroy
  
  is_indexed :fields => ["body"], :include => [{
      :association_name => "user",
      :field => "login",
      :as => "commented_by"
    }]
  
  attr_protected :user_id
    
  validates_presence_of :user_id, :target, :body, :project_id
  
  named_scope :with_shas, proc{|*shas| 
    {:conditions => { :sha1 => shas.flatten }, :include => :user}
  }
  
end
