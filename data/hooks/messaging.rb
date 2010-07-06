#--
#   Copyright (C) 2010 Tero Hänninen <tero.j.hanninen@jyu.fi>
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2009 Marius Mårnes Mathiesen <marius.mathiesen@gmail.com>
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
require 'rubygems'
require 'stomp'
require 'json'
require 'yaml'

print "=> Syncing Gitorious... "

class Publisher
  def connect
    stomp_server, stomp_port = stomp_server_and_port
    @connection = Stomp::Connection.open(nil, nil, stomp_server, stomp_port, true)
    @connected = true
  end
  
  def stomp_server_and_port
    gitorious_yaml = YAML::load_file(File.join(File.dirname(__FILE__), "..", "..", "config", "gitorious.yml"))[ENV['RAILS_ENV']]
    server = gitorious_yaml['stomp_server_address'] || 'localhost'
    host = (gitorious_yaml['stomp_server_port'] || '61613').to_i
    return [server, host]
  end

  def post_message(message)
    connect unless @connected
    @connection.send '/queue/GitoriousPushEvent', message, {'persistent' => true}
  end
end
