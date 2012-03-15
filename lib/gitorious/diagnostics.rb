
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
  module Diagnostics

    # Overall
    
    def everything_healthy?
      git_operations_work? &&
        queues_up? &&
        indexing_works? &&
        search_works? &&
        git_user_ok? &&
        gitorious_admin_account_present? &&
        repo_dir_ok? &&
        tarball_dirs_ok? &&
        git_daemon_up? &&
        poller_up? &&
        mysql_up? &&
        ultrasphinx_up? &&
        queue_service_up? &&
        memcached_up? &&
        sendmail_up? &&
        over_90_percent_disk_free? &&
        over_90_percent_RAM_free?
    end

    # Core functionality
    
    def git_operations_work?
      false
    end

    def queues_up?
      false
    end

    def indexing_works?
      false
    end

    def search_works?
      false
    end

    def git_user_ok?
      false
    end

    def gitorious_admin_account_present?
      false
    end

    def repo_dir_ok?
      false
    end

    def tarball_dirs_ok?
      false
    end

    # Services and daemons

    def git_daemon_up?
      false
    end

    def poller_up?
      false
    end

    def mysql_up?
      false
    end

    def ultrasphinx_up?
      false
    end

    def queue_service_up?
      false
    end

    def memcached_up?
      false
    end

    def sendmail_up?
      false
    end
    
    # Host system health

    def over_90_percent_disk_free?
      false
    end

    def over_90_percent_RAM_free?
      false
    end
    
  end
end










