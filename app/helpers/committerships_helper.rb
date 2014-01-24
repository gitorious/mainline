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
  def committer_group(group)
    if group.is_a?(SuperGroup)
      image_tag("super_group_avatar.png", class: 'gts-avatar') +
        link_to("Super Group*", "/about/faq")
    else
      group_avatar(group, :size => :icon) +
        link_to(group.to_param_with_prefix, group)
    end
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
