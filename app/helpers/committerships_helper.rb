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
module CommittershipsHelper
  def collaborators(label, permissions, collaborators)
    creator = t("views.repos.creator")
    creator_label = "<small class=\"hint\">#{creator}</small>"

    collab_items = collaborators.select{|c|User === c}.map do |user|
      <<-HTML
    <li>
      <div class="user">
        #{avatar_from_email(user.email, :size => 16, :style => "tiny")}
        #{link_to h(user.title), user}
        #{creator_label if @repository.user == user}
      </div>
    </li>
      HTML
    end

    msg = "No users with #{permissions} permissions"
    collab_items = "<li><em>#{msg}</em></li>" if collaborators.blank?

    <<-HTML
  <ul class="committers">
  <h5>#{label}</h5>
  #{collab_items}
  </ul>
    HTML
  end

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
