# Run with `env RAILS_ENV="development" proxymachine -c config/git-proxymachine.rb`

ENV["RAILS_ENV"] ||= "production"
require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)

class GitRouter
  # Lookup the real repository path based on +path+
  def self.lookup_repository(path)
    LOGGER.info "Looking up #{path.inspect}"
    ActiveRecord::Base.verify_active_connections!
    ::Repository.find_by_path(path)
  end

  def self.error_message(msg)
    message = ["\n----------------------------------------------"]
    message << msg
    message << "----------------------------------------------\n"
    sideband_message(message.join("\n"))
  end

  def self.sideband_message(message, channel = 2)
    msg = "%s%s" % [channel.chr, message]
    "%04x%s" % [msg.length+4, msg]
  end

  def self.header_tag(path)
    host = GitoriousConfig['gitorious_host']
    header_data = "git-upload-pack /#{path}\000host=#{host}\000"
    "%04x%s" % [header_data.length+4, header_data]
  end
end

# Do the proxying to the proper host, and send the real path onwards
# to the backend git-daemon
proxy do |data|
  if data =~ /^....(git\-upload\-pack|git\ upload\-pack)\s(.+)\x00host=(.+)\x00/
    service, path, host = $1, $2, $3
    if repository = GitRouter.lookup_repository(path)
      {
        :remote => "localhost:9400",
        :data => GitRouter.header_tag(repository.hashed_path + ".git")
      }
    else
      { :close => GitRouter.error_message("Cannot find repository #{path}") }
    end
  elsif data =~ /^....(git\-receive\-pack|git\ receive\-pack)/
    {
      :close => GitRouter.error_message("The git:// protocol is read-only.\n\n" +
        "Please use the push url as listed on the repository page.")
    }
  else
    { :noop => true }
  end
end
