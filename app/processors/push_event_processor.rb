class PushEventProcessor < ApplicationProcessor

  subscribes_to :push_event
  attr_reader :oldrev, :newrev, :action
  
  def on_message(message)
    hash = ActiveSupport::JSON.decode(message)
    logger.debug("Processor on message #{hash.inspect}")
    if @repository = Repository.find_by_hashed_path(hash['gitdir'])
      self.commit_summary = hash['message']
      log_events
    else
      logger.error("Processor received message, but couldn't find repo with hashed_path #{hash['gitdir']}")
    end
  end
  
  def log_events
    events.each do |e|
      log_event(e)
    end
  end
  
  def log_event(an_event)
    @project ||= Project.first#find_by_slug("bar")
    logger.debug("Processor: adding event #{an_event.message} from #{an_event.email}")
    @project.create_event(an_event.event_type, @repository, User.find_by_email(an_event.email), an_event.identifier, an_event.message, an_event.commit_time)
  end
  
  # Sets the commit summary, as served from git
  def commit_summary=(spec)
    @oldrev, @newrev, revname = spec.split(' ')
    r, name, @identifier = revname.split("/")
    @head_or_tag = name == 'tags' ? :tag : :head
  end
  
  def head?
    @head_or_tag == :head
  end
  
  def tag?
    @head_or_tag == :tag
  end
  
  def action
    @action ||= if oldrev =~ /^0+$/
      :create
    elsif newrev =~ /^0+$/
      :delete
    else
      :update
    end
  end
  
  def events
    @events ||= fetch_events
  end
  
  class EventForLogging
    attr_accessor :event_type, :identifier, :email, :message, :commit_time
    def to_s
      "Type: #{event_type} by #{email} at #{commit_time} with #{identifier}"
    end
  end
  
  def fetch_events
    if tag?
      e = EventForLogging.new
      e.event_type = action == :create ? Action::CREATE_TAG : Action::DELETE_TAG
      e.identifier = @identifier
      fetch_commit_details(e, @newrev)
      return [e]
    elsif action == :create
      e = EventForLogging.new
      e.event_type = Action::CREATE_BRANCH
      e.identifier = @identifier
      fetch_commit_details(e, @newrev)
      return [e]
    elsif action == :delete
      e = EventForLogging.new
      e.event_type = Action::DELETE_BRANCH
      e.identifier = @identifier
      fetch_commit_details(e, @oldrev)
      return [e]
    else
      events_from_git_log
    end
  end
  
  GIT_SEPARATOR = ";;"
  
  def fetch_commit_details(an_event, commit_sha)
    sha, email, timestamp, message = git.show({:pretty => git_pretty_format, :s => true}, commit_sha).split(GIT_SEPARATOR)
    an_event.email        = email
    an_event.commit_time  = Time.at(timestamp.to_i).utc
    an_event.message      = message
    logger.info("Processor returning #{an_event}")
  end
  
  def events_from_git_log
    result = []
    commits = git.log({:pretty => git_pretty_format, :s => true}, "#{@oldrev}..#{@newrev}").split("\n")
    commits.each do |c|
      sha, email, timestamp, message = c.split(GIT_SEPARATOR)
      e = EventForLogging.new
      e.identifier    = sha
      e.email         = email
      e.commit_time   = Time.at(timestamp.to_i).utc
      e.event_type    = Action::COMMIT
      e.message       = message
      result << e
    end
    return result
  end
  
  def git
    @git ||= @repository.git.git
  end
  
  def git_pretty_format
    fmt = ['%H','%ce','%at','%s'].join(GIT_SEPARATOR)
    "format:#{fmt}"
  end
end