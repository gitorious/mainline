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

class Admin::DiagnosticsController < ApplicationController
  include Gitorious::Diagnostics
  
  # TODO hide index (but not summary) behind admin user login filter
  
  def index
    @everything_healthy = markup(everything_healthy?)

    @git_operations_work = markup(git_operations_work?)
    @queues_up = markup(queues_up?)
    @indexing_works = markup(indexing_works?)
    @search_works = markup(search_works?)
    @git_user_ok = markup(git_user_ok?)
    @gitorious_admin_account_present = markup(gitorious_admin_account_present?)
    @repo_dir_ok = markup(repo_dir_ok?)
    @tarball_dirs_ok = markup(tarball_dirs_ok?)
    @authorized_keys_ok = markup(authorized_keys_ok?)

    @git_daemon_up = markup(git_daemon_up?)
    @poller_up = markup(poller_up?)
    @mysql_up = markup(mysql_up?)
    @ultrasphinx_up = markup(ultrasphinx_up?)
    @queue_service_up = markup(queue_service_up?)
    @memcached_up = markup(memcached_up?)
    @sendmail_up = markup(sendmail_up?)

    @enough_disk_free = markup(enough_disk_free?)
    @enough_RAM_free = markup(enough_RAM_free?)
    @healthy_cpu_load_average = markup(healthy_cpu_load_average?)

    @uptime_output = `uptime`
    @free_output = `free -m`
    @vmstat_output = `vmstat`
    @df_output = `df -h`
  end

  def summary
    if everything_healthy?
      render :text => "OK"
    else
      render :text => "Error! See /admin/diagnostics for overview", :status => 500
    end
  end  


  private

  def markup(status)
    if status == true
      "<span class='diagnostic-true-indicator'>true</span>"
    else
      "<span class='diagnostic-false-indicator'>false</span>"
    end
  end
  

    
end
