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
  before_filter :login_required, :except => :summary
  before_filter :require_site_admin, :except => :summary

  def index
    @everything_healthy = markup(everything_healthy?)

    # @git_operations_work = markup(git_operations_work?)
    @git_user_ok = markup(git_user_ok?)
    @rails_process_owned_by_git_user = markup(rails_process_owned_by_git_user?)
    @atleast_one_gitorious_account_present = markup(atleast_one_gitorious_account_present?)
    @repo_dir_ok = markup(repo_dir_ok?)
    @tarball_dirs_ok = markup(tarball_dirs_ok?)
    @authorized_keys_ok = markup(authorized_keys_ok?)

    @ssh_deamon_up = markup(ssh_deamon_up?)
    @git_daemon_up = markup(git_daemon_up?)
    @poller_up = markup(poller_up?)
    @mysql_up = markup(mysql_up?)
    @ultrasphinx_up = markup(ultrasphinx_up?)
    @queue_service_up = markup(queue_service_up?)
    @memcached_up = markup(memcached_up?)

    @enough_disk_free = markup(enough_disk_free?)
    @enough_RAM_free = markup(enough_RAM_free?)
    @healthy_cpu_load_average = markup(healthy_cpu_load_average?)

    @uptime_output = `uptime`
    @free_output = `free -m`
    @vmstat_output = `vmstat`
    @df_output = `df -h`
  end

  def summary
    if !Gitorious::ops?(request.remote_addr)
      render(:text => <<-EOF, :status => 403) and return
Error! The diagnostic summary page can only be reached from pre-approved
remote addresses. If you feel you are being stopped injustly, please contact
#{Gitorious.support_email}
      EOF
    end

    render(:text => "OK") and return if everything_healthy?

    render(:text => <<-EOF, :status => 500)
Error! Something might be broken in your Gitorious install.
See /admin/diagnostics for a detailed overview.
    EOF
  end

  private
  def markup(status)
    if status == true
      "<span class='diagnostic-true-indicator'>true</span>"
    else
      "<span class='diagnostic-false-indicator'>false</span>"
    end
  end

  def require_site_admin
    unless current_user.is_admin?
      redirect_to root_path
    end
  end
end
