
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
        git_user_ok? &&
        atleast_one_gitorious_account_present? &&
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
      # TODO
      # Needs initial config of test user/key
      # aDD Iinital step during setup
      # throw useful error in web console if not done yet
     
      # test project/repo
      # needs corresponding public key for a matching user in app
      # needs keypair for the gitorious user running the test
      # Could seed db with test user, and create priv key on first run
      # of diagnostic tool?
      # CAN TEST This seeding by grepping authorized_keys file
      
      # shell out, test clone/push/pull or just git ls-remote? of test repo
      # cleanup
      # ssh -i /var/www/gitorious/data/seeded_private_key
    end
    
    def git_user_ok?
      false
      # TODO
      # Check that gitorious_user, usually 'git', is present, in git group, has home dir, other??
    end

    def atleast_one_gitorious_account_present?
      false
      # TODO
    end

    def repo_dir_ok?
      false
      # TODO
    end

    def tarball_dirs_ok?
      false
      # TODO
    end

    def authorized_keys_ok?
      false
      # TODO
    end

    # TODO wire this up
    def not_using_reserved_hostname?
      !GitoriousConfig.using_reserved_hostname?
    end



    

    
    # TODO check for public mode correctly set up
    

    # Services and daemons


    def ssh_deamon_up?
      #TODO
    end

    
    def git_installed?
      #TODO
    end
    
    def git_daemon_up?
      # other altneratives: git-proxy, <nothing>
      # in our case also haproxy
      count_process_names_containing("git-daemon")
    end

    def poller_up?
      count_process_names_containing("poller")
    end

    def mysql_up?
      count_process_names_containing("mysql")
    end

    def ultrasphinx_up?
      count_process_names_containing("searchd")
      # TODO + does it respond on configured port, expected by rails app?
      # TODO check ps -o for pid, we got the pidfile for it
    end

    def queue_service_up?
      adapter_name = GitoriousConfig["messaging_adapter"]
      count_process_names_containing(adapter_name)
      # TODO can we ping stomp? queue service can be on remote box....
      # TODO just check if there's anyting on specified port for queue service
    end

    def memcached_up?
      count_process_names_containing("memcached")
    end

    def sendmail_up?
      count_process_names_containing("sendmail")
    end

    # TODO wire this up
    # BUT only for apache
    # Only useful/true if http_cloning is allowed
    def xsendfile_enabled?
      # TODO, one or two appropaches

      #1: enabled and confed in apache

      #2: can do:
      # curl
      # http://git.[gitorious_host]/gitorious/mainline.git/info/refs
      # -> fil
    end

    
    def count_process_names_containing(str)
      matching_processes_count = (`ps -ef | grep #{str} | grep -v grep | wc -l`.to_i)      
      matching_processes_count > 0
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










