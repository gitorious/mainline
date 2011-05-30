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
RAILS_ENV = ENV['RAILS_ENV'] || "production"
RAILS_ROOT = File.expand_path(File.join(File.readlink(File.readlink(File.dirname(File.expand_path(__FILE__)))), "..", ".."))

$: << File.join(RAILS_ROOT, "lib")
require 'rubygems'
require 'bundler'
ENV['BUNDLE_GEMFILE'] = File.join(RAILS_ROOT, "Gemfile")
Bundler.require :messaging, RAILS_ENV

require 'yaml'
require 'gitorious/messaging'

if !defined?(GitoriousConfig)
  conf = YAML::load_file(File.join(RAILS_ROOT, "config", "gitorious.yml"))
  GitoriousConfig = conf[RAILS_ENV]
  adapter = GitoriousConfig["messaging_adapter"] || "stomp"
  Bundler.require adapter.to_sym
  Gitorious::Messaging.load_adapter(adapter)
  Gitorious::Messaging.configure_publisher(adapter)
end

class Publisher
  include Gitorious::Messaging::Publisher

  def post_message(message)
    publish("/queue/GitoriousPush", message)
  end
end
