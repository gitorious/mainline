# -*- coding: utf-8 -*-
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
print "=> Syncing Gitorious... "
RAILS_ENV = ENV['RAILS_ENV'] || "production"
RAILS_ROOT = File.join(File.dirname(__FILE__), "..", "..")

$: << File.join(RAILS_ROOT, "lib")
require 'rubygems'
require 'yaml'
require 'gitorious/messaging'

if !defined?(GitoriousConfig)
  conf = YAML::load_file(File.join(RAILS_ROOT, "config", "gitorious.yml"))
  GitoriousConfig = conf[RAILS_ENV]
  Gitorious::Messaging.load_adapter(GitoriousConfig["messaging_adapter"])
  Gitorious::Messaging.configure_publisher(GitoriousConfig["messaging_adapter"])
end

class Publisher
  include Gitorious::Messaging::Publisher

  def post_message(message)
    publish("/queue/GitoriousPush", message)
  end
end
