# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class PushEventProcessor < ApplicationProcessor
  PUSH_EVENT_GIT_OUTPUT_SEPARATOR = "\t" unless defined?(PUSH_EVENT_GIT_OUTPUT_SEPARATOR) 
  PUSH_EVENT_GIT_OUTPUT_SEPARATOR_ESCAPED = "\\\t" unless defined?(PUSH_EVENT_GIT_OUTPUT_SEPARATOR_ESCAPED)
  subscribes_to :push_event
  attr_reader :oldrev, :newrev, :action, :user
  attr_accessor :repository
  
  def on_message(message)
    verify_connections!
    hash = ActiveSupport::JSON.decode(message)
    logger.debug("#{self.class.name} on message #{hash.inspect}")
    logger.info "Push event. Username is #{hash['username']}, commit summary is #{hash['message']}, gitdir is #{hash['gitdir']}"
    if @repository = Repository.find_by_hashed_path(hash['gitdir'])
      @user = User.find_by_login(hash['username'])
      process_push_from_commit_summary(hash['message'])
      log_events
    else
      logger.error("#{self.class.name} received message, but couldn't find repo with hashed_path #{hash['gitdir']}")
    end
  end

  def log_events
    logger.info("#{self.class.name} logging #{events.size} events")
    @events.each do |e|
      log_event(e)
    end
  end
  
  def log_event(an_event)
    @project ||= @repository.project
    event = @project.events.new(
      :action => an_event.event_type, 
      :target => @repository, 
      :user => an_event.user,
      :body => an_event.message,
      :data => an_event.identifier,
      :created_at => an_event.commit_time
      )
    if event.user.blank?
      event.email = an_event.email
    end
    event.save!
    if commits = an_event.commits
      commits.each do |c|
        commit_event = event.build_commit({
          :user => c.user,
          :created_at => c.commit_time,
          :email => c.email,
          :body => c.message,
          :data => c.identifier
        })
        commit_event.save!
      end
    end
  end
  
  # Sets the commit summary, as served from git
  def process_push_from_commit_summary(spec)
    @oldrev, @newrev, @revname = spec.split(' ')
    r, name, @identifier = @revname.split("/", 3)
    @target = {'tags' => :tag, 'heads' => :head, 'merge-requests' => :review}[name]
    if @target != :review && @repository
      @repository.update_attribute(:last_pushed_at, Time.now.utc)
    end
    process_push
  end
  
  def head?
    @target == :head
  end
  
  def tag?
    @target == :tag
  end
  
  def review?
    @target == :review
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
    @events
  end
  
  class EventForLogging
    attr_accessor :event_type, :identifier, :email, :message, :commit_time, :user
    attr_reader :commits
    def to_s
      "<PushEventProcessor:EventForLogging type: #{event_type} by #{email} at #{commit_time} with #{identifier}>"
    end
    
    def commits=(commits)
      @commits = commits
    end
  end

  def process_push
    @events = []
    case action
    when :create
      case @target
      when :head
        e = EventForLogging.new
        e.event_type = Action::CREATE_BRANCH
        e.message = "New branch"
        e.identifier = @identifier
        e.user = user
        result = [e]
        if @identifier == 'master'
          result = result + events_from_git_log(@newrev) 
        end
        result.each{|ev|@events << ev}
      when :tag
        e = EventForLogging.new
        e.event_type = Action::CREATE_TAG
        e.identifier = @identifier
        rev, message = [@newrev, "Created tag #{@identifier}"]
        logger.debug("Processor: action is #{action}, identifier is #{@identifier}, rev is #{rev}")
        fetch_commit_details(e, rev)
        e.user = user
        e.message = message
        @events << e        
      when :review
        # noop
        return
      end
    when :update
      case @target
      when :head
        e = EventForLogging.new
        e.event_type = Action::PUSH
        e.message = "#{@identifier} changed from #{@oldrev[0,7]} to #{@newrev[0,7]}"
        e.identifier = @identifier
        e.email = user.email
        e.commits = events_from_git_log("#{@oldrev}..#{@newrev}")
        @events << e
      when :tag
      when :review
        merge_request = MergeRequest.find(@identifier)
        merge_request.update_from_push!
      end
    when :delete
      case @target
      when :head
        e = EventForLogging.new
        e.event_type = Action::DELETE_BRANCH
        e.identifier = @identifier
        fetch_commit_details(e, @oldrev, Time.now.utc)
        e.user = user
        @events << e
      when :tag
        e = EventForLogging.new
        e.event_type = Action::DELETE_TAG
        e.identifier = @identifier
        rev, message = [@oldrev, "Deleted tag #{@identifier}"]
        logger.debug("Processor: action is #{action}, identifier is #{@identifier}, rev is #{rev}")
        fetch_commit_details(e, rev)
        e.message = message
        @events << e
      when :review
        # noop
        return
      end
    end
  end
    
  def fetch_commit_details(an_event, commit_sha, event_timestamp = nil)
    sha, email, timestamp, message = git.show({
      :pretty => git_pretty_format, 
      :s => true
    }, commit_sha).split(PUSH_EVENT_GIT_OUTPUT_SEPARATOR_ESCAPED)
    an_event.email        = email
    an_event.commit_time  = event_timestamp || Time.at(timestamp.to_i).utc
    an_event.message      = message
  end
  
  def events_from_git_log(revspec)
    result = []
    
    commits = encode(git.log({
      :pretty => git_pretty_format, 
      :s => true,
      :timeout => false,
    }, revspec)).split("\n")
    commits.each do |c|
      sha, email, timestamp, message = c.split(PUSH_EVENT_GIT_OUTPUT_SEPARATOR_ESCAPED)
      e = EventForLogging.new
      if email
        email = email.gsub(/\\(<|>)/, '\1')
        if user = User.find_by_email_with_aliases(Grit::Actor.from_string(email).email || Grit::Actor.from_string(email).name)
          e.user = user
        else
          e.email = email
        end
      end
      e.identifier    = sha
      e.commit_time   = Time.at(timestamp.to_i).utc
      e.event_type    = Action::COMMIT
      e.message       = message
      result << e
    end
    
    result
  end
  
  def git
    @git ||= @repository.git.git
  end
  
  def git_pretty_format
    fmt = ['%H','%cn <%ce>','%at','%s'].join(PUSH_EVENT_GIT_OUTPUT_SEPARATOR)
    "format:#{fmt}"
  end
  
  def encode(data)
    if RUBY_VERSION > '1.9'
      if !data.valid_encoding?
        data = data.force_encoding("utf-8")
        if !data.valid_encoding?
          # If there's something wonky with the data encoding still then brute force
          # conversion to utf-8, replacing bad chars (and potentially more)
          ec = Encoding::Converter.new("ASCII-8BIT", "utf-8", {
            :invalid => :replace, :undef => :replace
          })
          ec.convert(data)
        else
          data
        end
      else
        data
      end
    else
      data
    end
  end
end
