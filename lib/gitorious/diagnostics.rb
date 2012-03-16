
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
        authorized_keys_ok? &&
        git_daemon_up? &&
        poller_up? &&
        mysql_up? &&
        ultrasphinx_up? &&
        queue_service_up? &&
        memcached_up? &&
        sendmail_up? &&
        enough_disk_free? &&
        enough_RAM_free? &&
        healthy_cpu_load_average?
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

    def authorized_keys_ok?

    end

    # Services and daemons

    def git_daemon_up?
      false
    end

    def poller_up?
      count_process_names_containing("poller")
    end

    def mysql_up?
      count_process_names_containing("mysql")
    end

    def ultrasphinx_up?
      count_process_names_containing("ultrasphinx")
    end

    def queue_service_up?
     count_process_names_containing("stomp")
    end

    def memcached_up?
      count_process_names_containing("memcached")
    end

    def sendmail_up?
      count_process_names_containing("sendmail")
    end

    def count_process_names_containing(str)
      ('ps -ef | grep #{str} | grep -v grep | wc -l'.to_i) > 0
    end
    
    # Host system health

    # TODO make these thresholds configurable, with sane defaults
    # TODO option to make Gitorious run self-diagnostics regularly
    # (cron) and alert admin by mail if something breaks
    
    MAX_HEALTHY_DISK_USAGE = 90 #%
    
    def enough_disk_free?
      percent_str = `df -Ph #{GitoriousConfig['repository_base_path']} | awk 'NR==2 {print $5}'`
      percent_str.chomp "%"
      percent_free = percent_free.to_i
      return (percent_free < MAX_HEALTHY_DISK_USAGE)
    end

    MAX_HEALTHY_RAM_USAGE = 90 #%
    
    def enough_RAM_free?
      free_numbers = `free -mt | tail -n 1`.chomp.split(" ")
      total = free_numbers[1].to_i
      free = free_numbers[3].to_i
      percent_free = (free*100)/total
      return (percent_free > (100-MAX_HEALTHY_RAM_USAGE))
    end

    MAX_HEALTHY_CPU_LOAD = 90 #%
    
    def healthy_cpu_load_average?
      load_percent_last_15_min = `uptime`.chomp.split(" ").last.to_f
      return (load_percent_last_15_min < MAX_HEALTHY_CPU_LOAD.to_f)
    end
    
  end
end










