
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
      #git_operations_work? &&
        web_interface_reachable? &&
        git_user_ok? &&
        rails_process_owned_by_git_user? &&
        atleast_one_gitorious_account_present? &&
        repo_dir_ok? &&
        tarball_dirs_ok? &&
        authorized_keys_ok? &&
        not_using_reserved_hostname? &&
        ssh_deamon_up? &&
        git_daemon_up? &&
        poller_up? &&
        mysql_up? &&
        ultrasphinx_up? &&
        queue_service_up? &&
        memcached_up? &&
        enough_disk_free? &&
        enough_RAM_free? &&
        healthy_cpu_load_average?
    end

    def ascii_test(label)
      test_result = yield
      green = "\x1b[32m"
      red = "\x1b[31m"
      status_color = test_result ? green : red
      reset = "\x1b[0m"
      ("#{status_color}#{label}".ljust(50)+"#{test_result}#{reset}")
    end
    
    def health_text_summary
      puts ascii_test("everything healthy?"){ everything_healthy? }

      # @git operations work?  #{git_operations_work?}"
      puts ascii_test("git user ok?") {git_user_ok?}
      puts ascii_test("gitorius front web page is up?"){web_interface_reachable?}
      puts ascii_test("rails process present & owned by git user?"){rails_process_owned_by_git_user?}
      puts ascii_test("atleast one gitorious account present?") {atleast_one_gitorious_account_present?}
      puts ascii_test("repo base dir present, owned by git user?"){repo_dir_ok?}
      puts ascii_test("tarball dirs present, owned by git user?"){tarball_dirs_ok?}
      puts ascii_test("git user has ~/.ssh/authorized_keys file?"){authorized_keys_ok?}
      puts ascii_test("hostname not bound to a 'git.*' subdomain?"){not_using_reserved_hostname?}

      puts ascii_test("ssh deamon is up?"){ssh_deamon_up?}
      puts ascii_test("git daemon is up?"){git_daemon_up?}
      puts ascii_test("poller is up?"){poller_up?}
      puts ascii_test("mysql is up?"){mysql_up?}
      puts ascii_test("ultrasphinx is up?"){ultrasphinx_up?}
      puts ascii_test("queue service is up?"){queue_service_up?}
      puts ascii_test("memcached is up?"){memcached_up?}

      puts ascii_test("enough disk free?"){enough_disk_free?}
      puts ascii_test("enough RAM free?"){enough_RAM_free?}
      puts ascii_test("healthy cpu load average?"){healthy_cpu_load_average?}

      puts "\n\nuptime:\n"
      puts `uptime`
      puts "\n\nfree:\n"
      puts `free -m`
      puts "\n\nvmstat:\n"
      puts `vmstat`
      puts "\n\ndf:\n"
      puts `df -h`
    end

    
    
    # Core functionality

    # TODO finish this one and wire it up 
    def git_operations_work?
      false
      # Needs initial config of test user/key
      # Add initial step during server config
      # throw useful error in web console if this isnt done
     
      # test project/repo
      # needs corresponding public key for a matching user in app
      # needs keypair for the gitorious user running the test
      # Could seed db with test user, and create priv key on first run
      # of diagnostic tool?
      # CAN TEST This seeding by grepping authorized_keys file
      
      # shell out, test clone/push/pull or just git ls-remote? of test repo
      # ssh -i /var/www/gitorious/data/seeded_private_key

      # do cleanup before and after test run
    end
    
    def web_interface_reachable?
      `curl --silent localhost:80 | grep Gitorious | wc -l`.to_i > 0 
    end

    def git_user_ok?
      user_exists?(git_user)
    end

    def rails_process_owned_by_git_user?
      `ps U #{git_user} | grep Rails | wc -l`.to_i > 0
    end
    
    def atleast_one_gitorious_account_present?
      User.count > 0
    end

    def repo_dir_ok?
      path = RepositoryRoot.default_base_path
      (dir_present?(path) && owned_by_user?(path, git_user))
    end

    def tarball_dirs_ok?
      cache_path = GitoriousConfig["archive_cache_dir"]
      work_path = GitoriousConfig["archive_work_dir"]
      
      (dir_present?(cache_path) &&
       owned_by_user?(cache_path, git_user) &&
       dir_present?(work_path) &&
       owned_by_user?(work_path, git_user))
    end

    def authorized_keys_ok?
      path = File.expand_path("~/.ssh/authorized_keys")
      (file_present?(path) && owned_by_user?(path, git_user))
    end

    def not_using_reserved_hostname?
      !GitoriousConfig.using_reserved_hostname?
    end

    # TODO impl and wire this one up as well
    def outbound_mail_delivery_working?
      false
    end
    
    # TODO impl and wire this one up as well
    def public_mode_correctly_setup?
      false
    end

    # Services and daemons

    def ssh_deamon_up?
      atleast_one_process_name_matching("sshd")
    end

    def git_daemon_up?
      # TODO handle all known alternatives: git-proxy, <nothing>
      # + in gitorious.org case, also haproxy
      atleast_one_process_name_matching("git-daemon") ||
        atleast_one_process_name_matching("git-proxy")
    end

    def poller_up?
      atleast_one_process_name_matching("poller")
    end

    def mysql_up?
      atleast_one_process_name_matching("mysqld")
    end

    def ultrasphinx_up?
      atleast_one_process_name_matching("searchd")
      # TODO + does it respond on configured port, expected by rails app?
      # TODO check ps -o for pid, we got the pidfile for it
    end

    def queue_service_up?
      if GitoriousConfig["messaging_adapter"] != "sync"
        return (atleast_one_process_name_matching("stomp") ||
                atleast_one_process_name_matching("resque") ||
                atleast_one_process_name_matching("activemq"))
      else
        true
      end
      # TODO can we ping stomp? queue service can be on remote box....
      # TODO just check if there's anything on specified port for queue service
    end

    def memcached_up?
      atleast_one_process_name_matching("memcached")
    end

    # TODO impl and wire this one up as well
    def xsendfile_enabled?
      # NOTE: should only be used for apache
      # Only useful/true if http_cloning is allowed
      
      # TODO, one or two appropaches
      #1: enabled and confed in apache
      #2: can do:
      # curl
      # http://git.[gitorious_host]/gitorious/mainline.git/info/refs
      # -> fil
    end

   
    # Host system health
    
    MAX_HEALTHY_DISK_USAGE = 90 #%
    
    def enough_disk_free?
      percent_str = `df -Ph #{RepositoryRoot.default_base_path} | awk 'NR==2 {print $5}'`
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


    
    private
     
    def atleast_one_process_name_matching(str)
      matching_processes_count = (`ps -efww | grep #{str} | grep -v grep | wc -l`.to_i)
      matching_processes_count > 0
    end

    def dir_present?(path)
      Dir[path].count > 0
    end

    def file_present?(path)
      File.exist?(path)
    end

    def owned_by_user?(path, username)
      file_owner_uid = File.stat(path).uid.to_i
      user_uid = `id -u #{username}`.chomp.to_i
      (user_uid != 0 && (file_owner_uid == user_uid))
    end

    def user_exists?(username)
      `grep '^#{username}' /etc/passwd`
      ($? == 0)
    end

    def current_user?(username)
      ENV['USER'] == username
    end

    def git_user
      GitoriousConfig["gitorious_user"]
    end
  end
end










