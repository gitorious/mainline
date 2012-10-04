# Wrapper script for Gitorious-related CLIs
# It will :
# - set up an environment for bundler
# - check if a specific user is required in gitorious.yml
# - if so: check if we are it
# - if not and we are root: setuid+setgid to that user
# - if not and we are not root, fail

module Gitorious
  class CLI
    def run_with_gitorious_environment
      setup_environment
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

    def require_valid_user!
      if rails_env == "production"
        if git_user = gitorious_config("gitorious_user")
          etc_user = Etc.getpwnam(git_user)
          uid = etc_user.uid
          gid = etc_user.gid
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

    def gitorious_config(key)
      YAML::load_file(rails_root + "/config/gitorious.yml")[rails_env][key]
    end

    def rails_env
      ENV["RAILS_ENV"]
    end
  end
end
