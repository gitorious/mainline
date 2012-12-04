# Wrapper script for Gitorious-related CLIs
# It will :
# - set up an environment for bundler
# - check if a specific user is required in gitorious.yml
# - if so: check if we are it
# - if not and we are root: setuid+setgid to that user
# - if not and we are not root, fail
$: << "./lib"
require "gitorious/configuration_loader"
require "gitorious/messaging"

module Gitorious
  class CLI
    def run_with_gitorious_environment
      setup_environment
      load_config
      require_valid_user!
      yield
    end

    def setup_environment
      require "pathname"
      require "rubygems"
      ENV["BUNDLE_GEMFILE"] = (Pathname(rails_root) + "Gemfile").to_s
      ENV["RAILS_ENV"] ||= "production"
      Dir.chdir(rails_root)
      require "bundler/setup"
    end

    def rails_root
      rails_root ||= (Pathname(__FILE__) + "../../").realpath.to_s
    end

    def rails_env
      ENV["RAILS_ENV"]
    end

    def load_config
      loader = Gitorious::ConfigurationLoader.new
      loader.load_configurable_singletons(rails_root)
      config = loader.configure_singletons(rails_env)
      config
    end

    def require_valid_user!
      if rails_env == "production"
        if git_user = Gitorious.user
          etc_user = Etc.getpwnam(git_user)
          uid = etc_user.uid
          gid = etc_user.gid
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
