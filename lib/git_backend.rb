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

require "fileutils"

class GitBackend
  class << self
    # Creates a new bare Git repository at +path+
    # sets git-daemon-export-ok if +set_export_ok+ is true (default)
    def create(repos_path, set_export_ok = true)
      FileUtils.mkdir_p(repos_path, :mode => 0750)
      Dir.chdir(repos_path) do |path| 
        template = File.expand_path(File.join(File.dirname(__FILE__), "../data/git-template"))
        git = Grit::Git.new(path)
        git.init(:template => template)
        post_create(path) if set_export_ok
      end
    end
    
    # Clones a new bare Git repository at +target-path+ from +source_path+
    # sets git-daemon-export-ok if +set_export_ok+ is true (default)
    def clone(target_path, source_path, set_export_ok = true)
      parent_path = File.expand_path(File.join(target_path, ".."))
      FileUtils.mkdir_p(parent_path, :mode => 0750)
      template = File.expand_path(File.join(File.dirname(__FILE__), "../data/git-template"))
      git = Grit::Git.new(target_path)
      git.clone({:bare => true, :template => template}, source_path, target_path)
      post_create(target_path) if set_export_ok
    end
    
    def delete!(repos_path)
      if repos_path.index(RepositoryRoot.default_base_path) == 0
        FileUtils.rm_rf(repos_path)
      else
        raise "bad path"
      end
    end
    
    def repository_has_commits?(repos_path)
      Dir[File.join(repos_path, "refs/heads/*")].size > 0
    end
    
    protected
      def post_create(path)
        FileUtils.touch(File.join(path, "git-daemon-export-ok"))
        execute_command(%Q{GIT_DIR="#{path}" git update-server-info})
      end
      
      def execute_command(command)
        system(command)
      end
  end
end

