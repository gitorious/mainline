# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class AddPermissionsToCommitterships < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :committerships, :permissions, :integer
      Committership.reset_column_information
      base_perms = Committership::CAN_REVIEW | Committership::CAN_COMMIT
      say_with_time("Updating existing permissions") do
        Committership.includes(:repository => [:user]).each do |c|
          if c.repository &&
              (c.committer == c.repository.owner || c.committer == c.repository.user)
            c.permissions = base_perms | Committership::CAN_ADMIN
          else
            c.permissions = base_perms
          end
          c.save!
        end
      end
    end
  end

  def self.down
    remove_column :committerships, :permissions
  end
end
