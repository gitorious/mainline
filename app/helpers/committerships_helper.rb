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
  def confirmation_if_sole_admin(committership)
    if last_admin(committership.repository, committership)
      "You are about to remove the last committer with admin rights. Are you sure about this?"
    end
  end

  def last_admin(repo, to_be_removed)
    admins = repo.committerships.admins
    (admins.size == 1 && admins.first == to_be_removed)
  end

  def super_group?(committership)
    committership.id == SuperGroup.id
  end

  def checkboxes(f)
    cs = f.object
    <<HTML.html_safe
&nbsp;&nbsp;<label class="checkbox">#{check_box_tag("permissions[]", "review", cs.reviewer?)} #{f.label("Review")}</label>
&nbsp;&nbsp;<label class="checkbox">#{check_box_tag("permissions[]", "commit", cs.committer?)} #{f.label("Commit")}</label>
&nbsp;&nbsp;<label class="checkbox">#{check_box_tag("permissions[]", "admin", cs.admin?)} #{f.label("Administer")}</label>
&nbsp;&nbsp;
HTML
  end
end
