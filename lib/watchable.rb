# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

# By including this module in an AR::Base descendant, this class becomes watchable:
# - has_many :favorites
# - receives instance methods
module Watchable

  def self.included(base)
    base.has_many :favorites, :as => :watchable, :dependent => :destroy
    base.has_many :watchers, :through => :favorites, :source => :user
  end

  def watched_by?(user)
    watchers.include?(user)
  end

  def watched_by!(a_user)
    a_user.favorites.create!(:watchable => self, :notify_by_email => a_user.default_favorite_notifications)
  end
end
