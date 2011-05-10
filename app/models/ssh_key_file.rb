# encoding: utf-8
#--
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

# FIXME: this class acts too much like a singleton: read the file contents on
# initialize and mark it as dirty and reload only when needed.
class SshKeyFile
  def initialize(path=nil)
    @path = path || default_authorized_keys_path
  end
  attr_accessor :path
  
  def contents
    File.read(@path)
  end

  def add_key(key)
    File.open(@path, "a", 0600) do |file|
      file.flock(File::LOCK_EX)
      file << key
      file.flock(File::LOCK_UN)
    end
  end

  def delete_key(key)
    data = File.read(@path)
    return true unless data.include?(key)
    new_data = data.gsub(key, "")
    File.open(@path, "w") do |file|
      file.flock(File::LOCK_EX)
      file.puts new_data
      file.flock(File::LOCK_EX)
    end
  end
  
  protected
    def default_authorized_keys_path
      File.join(File.expand_path("~"), ".ssh", "authorized_keys")
    end
end
