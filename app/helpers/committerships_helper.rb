# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
module CommittershipsHelper
  def confirmation_if_sole_admin(repo, committership)
    if last_admin(repo, committership)
      "You are about to remove the last committer with admin rights. Are you sure about this?"
    end
  end

  def last_admin(repo, to_be_removed)
    admins = repo.committerships.select { |c| c.admin? }
    (admins.size == 1 && admins.first == to_be_removed)
  end
end
