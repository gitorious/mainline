# encoding: utf-8
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

# Wrapper script for Gitorious-related CLIs
# It will :
# - set up an environment for bundler
# - check if a specific user is required in gitorious.yml
# - if so: check if we are it
# - if not and we are root: setuid+setgid to that user
# - if not and we are not root, fail

module Gitorious
  class CLI
    def run_with_gitorious_environment(options={})
      setup_environment(options)
      load_config
      require_valid_user!
      yield
    end

    def setup_environment(options)
      require "pathname"
      require "rubygems"
      ENV["BUNDLE_GEMFILE"] = (Pathname(rails_root) + "Gemfile").to_s
      ENV["RAILS_ENV"] ||= "production"
      Dir.chdir(rails_root)
      require "bundler/setup" unless options[:skip_bundler]
    end

    def rails_root
      rails_root ||= (Pathname(__FILE__) + "../../").realpath.to_s
    end

    def rails_env
      ENV["RAILS_ENV"]
    end

    def load_config
      $LOAD_PATH << rails_root + "/lib"
      require "./lib/gitorious/configuration_loader"
      require "./lib/gitorious/messaging"
      loader = Gitorious::ConfigurationLoader.new(rails_root)
      loader.require_configurable_singletons!
      config = loader.configure_application!(rails_env)
      config
    end

    def require_valid_user!
      if rails_env == "production"
        if git_user = Gitorious.user
          etc_user = Etc.getpwnam(git_user)
          uid = etc_user.uid
          if git_group = Etc.getgrnam(git_user)
            gid = git_group.gid
          else
            gid = etc_user.gid
          end
          ENV["HOME"] = etc_user.dir
          current_userid = Process.euid
          if current_userid == uid
            # OK, running as correct user
          else
            if current_userid == 0
              Process::GID.change_privilege(gid)
              Process::UID.change_privilege(uid)
            else
              raise "You need to be root to do this!"
            end
          end
        end
      end
    end
  end
end
