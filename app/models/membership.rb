# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user
  belongs_to :role
  has_many :messages, :as => :notifiable
  before_destroy :dont_delete_group_creator
  before_destroy :nullify_messages
  attr_accessor :inviter

  def breadcrumb_parent
    Breadcrumb::Memberships.new(group)
  end

  def title
    "Member"
  end

  def uniq?
    membership = Membership.where(:user_id => user_id, :group_id => group_id).first
    membership.nil? || membership == self
  end

  protected
  def dont_delete_group_creator
    return user != group.creator
  end

  def nullify_messages
    messages.update_all({:notifiable_id => nil, :notifiable_type => nil})
  end
end
