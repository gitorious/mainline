# -*- coding: utf-8 -*-
#--
#   Copyright (C) 2013 Gitorious AS
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

module Gitorious
  class CustomHook
    def initialize(hook, env = "production")
      @hook = hook
      @env = env
    end

    def path
      return @file if defined?(@file)
      @file = File.join(File.dirname(__FILE__), "../../data/hooks/custom-#{@hook}")
      return File.expand_path(@file) if File.executable?(@file)

      if !defined?(Gitorious::Configuration)
        require "gitorious/configuration_loader"
        loader = Gitorious::ConfigurationLoader.new
        loader.configure_application!(@env)
      end

      @file = Gitorious::Configuration.get("custom_#{@hook.gsub(/\-/, '_')}_hook")
    end

    def exists?
      !path.nil? && File.exist?(path)
    end

    def executable?
      !path.nil? && File.executable?(path)
    end

    def execute(args, input = "")
      return if !executable?
      argstr = args.length > 0 ? "#{args.join(' ')} " : ""

      IO.popen("#{path} #{argstr}2>&1", "w+") do |child_process|
        child_process.write(input)
        child_process.close_write
        child_process.read.split("\n").each do |l|
          puts "#{l}\n"
        end
      end

      $?
    end
  end
end
