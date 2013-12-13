#--
#   Copyright (C) 2012-2013 Gitorious AS
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

def each_version
  pattern = /^v(\d+\.\d+\.\d+)/

  `#{ENV["GIT"] || "git"} tag -n`.split("\n").reverse.each do |line|
    next unless line =~ pattern
    nothing, version, *description = line.split(pattern)
    yield version, description.join
  end
end

def list_versions
  puts "\nAvailable versions"
  newest = true

  each_version do |version, description|
    color = newest ? "32" : "31"
    newest = false

    if Gitorious::VERSION == version
      print "-> \033[1m\033[#{color}mv#{version}\033[0m"
    else
      print "   v#{version}"
    end

    puts "    #{description}"
  end
end

def describe_version(version)
  puts "\nChanges between v#{Gitorious::VERSION} and v#{version}:"

  each_version do |v, description|
    next if v <= Gitorious::VERSION || v > version
    puts v
    puts `#{ENV['GIT'] || 'git'} tag -l v#{v} -n9999`.split("\n")[2..-1].join("\n")
  end
end

def show_changelog
  require File.join(File.dirname(__FILE__), "../gitorious")

  system("#{ENV['GIT'] || 'git'} fetch git://gitorious.org/gitorious/mainline.git 2> /dev/null")

  if ENV["VERSION"]
    describe_version(ENV["VERSION"])
  else
    list_versions
  end
end


task :changelog do
  show_changelog
end

namespace :versioning do
  desc "List commits not versioned yet"
  task :unreleased do
    log_spec = "v#{Gitorious::VERSION}..HEAD"
    command = %Q[#{ENV['GIT'] || "git"} log #{log_spec}]
    header = "Commits not yet versioned in Gitorious:"
    puts "\n#{header}"
    puts "=" * header.size + "\n"
    exec command
  end

  desc "Show current and available Gitorious versions and details about individual versions"
  task :changelog do
    show_changelog
  end
end
