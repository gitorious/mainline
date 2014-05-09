# encoding: utf-8
#--
#   Copyright (C) 2011-2014 Gitorious AS
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

# Run with `env RAILS_ENV="development" proxymachine -c config/git-proxymachine.rb`

ENV["RAILS_ENV"] ||= "production"
require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)

class GitRouter
  # Lookup the real repository path based on +path+
  def self.lookup_repository(path)
    LOGGER.info "Looking up #{path.inspect}"
    ActiveRecord::Base.verify_active_connections!
    ::Repository.find_by_path(path)
  end

  def self.error_message(msg)
    message = ["\n----------------------------------------------"]
    message << msg
    message << "----------------------------------------------\n"
    sideband_message(message.join("\n"))
  end

  def self.sideband_message(message, channel = 2)
    msg = "%s%s" % [channel.chr, message]
    "%04x%s" % [msg.length+4, msg]
  end

  def self.header_tag(path)
    host = Gitorious.host
    header_data = "git-upload-pack /#{path}\000host=#{host}\000"
    "%04x%s" % [header_data.length+4, header_data]
  end
end

# Do the proxying to the proper host, and send the real path onwards
# to the backend git-daemon
remote_host = ENV['GIT_DAEMON_PORT_9418_TCP_ADDR'] || 'localhost'
remote_port = ENV['GIT_DAEMON_PORT_9418_TCP_PORT'] || 9400
remote = "#{remote_host}:#{remote_port}"

proxy do |data|
  if data =~ /^....(git\-upload\-pack|git\ upload\-pack)\s(.+)\x00host=(.+)\x00/
    service, path, host = $1, $2, $3
    if repository = GitRouter.lookup_repository(path)
      {
        :remote => remote,
        :data => GitRouter.header_tag(repository.hashed_path + ".git")
      }
    else
      { :close => GitRouter.error_message("Cannot find repository #{path}") }
    end
  elsif data =~ /^....(git\-receive\-pack|git\ receive\-pack)/
    {
      :close => GitRouter.error_message("The git:// protocol is read-only.\n\n" +
        "Please use the push url as listed on the repository page.")
    }
  else
    { :noop => true }
  end
end
