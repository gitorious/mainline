#--
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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

class Event < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :target, :polymorphic => true
  validates_presence_of :user_id, :unless => :user_email_set?

  def email=(an_email)
    if u = User.find_by_email(an_email)
      self.user = u
    else
      self.user_email = an_email
    end
  end

  def email
    user_email || user.email
  end
  
  def email_display
    email.split("@").first
  end

  protected
  def user_email_set?
    !!user_email
  end
end
