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
require "pathname"

root = Pathname(__FILE__) + "../../../"
File.read(root + ".gitmodules").scan(/path = (.*)/).each do |s|
  if !File.exist?(root + s.first)
    $stderr.puts "Git submodule #{s.first} not present."
    $stderr.puts "Did you initialize and update submodules?"
    $stderr.puts ""
    $stderr.puts "    git submodule update --init --recursive"
    $stderr.puts "    bundle exec rake assets:clear"
    $stderr.puts ""
    $stderr.puts "It is STRONGLY recommended that you resolve this issue."
    $stderr.puts "The web application will not behave properly as long as"
    $stderr.puts "this issue persists."
  end
end
