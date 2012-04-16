
# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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


module Gitorious
  module UserAdministration

    def suspend_user(user)
      summarized do |s|
        s << suspend_account(user) 

        if(user.groups.count > 0) 
          s << remove_from_teams(user)
        end

        if(committership_count(user) > 0)
          s << remove_committerships(user)
        end
      end
    end
     
    protected
    
    def committership_count(user)
      Committership.all(:conditions => {:committer_id => user.id, :committer_type => "User"}).count
    end

    def suspend_account(user)
      summarized do |s|
        user.suspend
        user.save
        s << " "+I18n.t("admin.user_suspend.suspended_cannot_log_back_in_or_run_git_ops")
      end
    end
    
    def remove_from_teams(user)
      summarized do |s|
        groups = user.groups
        groups.each do |g| 
          g.members.delete(user)
          g.save
        end
        group_names = groups.map { |g| g.name }.join(", ")
        s << " "+I18n.t("admin.user_suspend.removed_user_from_teams", :group_names => group_names)
      end
    end

    def remove_committerships(user)
      summarized do |s|
        committerships = Committership.all(:conditions => {:committer_id => user.id, :committer_type => "User"})

        repos = [] 
        committerships.each do |c|
          if c.repository
            repos << c.repository
          end
          c.delete
        end
        
        repo_names = repos.uniq.map { |r| r.name }.join(", ")
        s << " "+I18n.t("admin.user_suspend.removed_user_committerships_from_repos", :repo_names => repo_names)
      end
    end
    
    def teams_orphaned_by_user_leaving(user)
      member_groups = user.groups
      user.groups.find_all{ |group| sole_admin?(user, group)}
    end

    def sole_admin?(user, group)
      admins = group.memberships.select{|m| m.role.name == "Administrator"}
      admins.none? {|a| a.user != user}
    end

    def projects_orphaned_by_user_leaving(user)
      orphans = Project.all(:conditions => {:owner_id => user.id, :owner_type => "User"})
    end

    private
      
    def summarized
      summary = ""
      yield(summary)
      return summary
    end

  end
end










