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
require "pathname"

class RailsEnv
  def initialize(env); @env = env; end
  def production?; @env == "production"; end
  def development?; @env == "development"; end
  def test?; @env == "test"; end
  def to_s; @env; end
end

module Rails
  def self.root
    @root ||= Pathname(__FILE__).realpath + "../../../"
  end

  def self.env
    @env ||= RailsEnv.new(ENV["RAILS_ENV"] || "production")
  end
end

$: << Rails.root + "lib"
require "rubygems"
require "bundler"
ENV["BUNDLE_GEMFILE"] = Rails.root + "Gemfile"
Bundler.require :messaging, Rails.env.to_s

require "yaml"
require "gitorious/messaging"

if !defined?(GitoriousConfig)
  conf = YAML::load_file(Rails.root + "config/gitorious.yml")
  GitoriousConfig = conf[Rails.env.to_s]
  adapter = GitoriousConfig["messaging_adapter"] || "stomp"
  Bundler.require adapter.to_sym
  Gitorious::Messaging.load_adapter(adapter)
  Gitorious::Messaging.configure_publisher(adapter)
  if adapter == "resque"
    resque_config = Rails.root + "config/resque.yml"
    if resque_config.exist?
      settings = YAML::load_file(resque_config)[Rails.env.to_s]
      Resque.redis = settings if settings
    end
  end
end

class Publisher
  include Gitorious::Messaging::Publisher

  def post_message(message)
    publish("/queue/GitoriousPush", message)
  end
end
