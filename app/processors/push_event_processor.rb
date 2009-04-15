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
    hash = ActiveSupport::JSON.decode(message)
    logger.debug("Processor on message #{hash.inspect}")
    if @repository = Repository.find_by_hashed_path(hash['gitdir'])
      @user = User.find_by_login(hash['username'])
      @repository.update_attribute(:last_pushed_at, Time.now.utc)
      self.commit_summary = hash['message']
      log_events
    else
      logger.error("Processor received message, but couldn't find repo with hashed_path #{hash['gitdir']}")
    end
  end
  
  def log_events
    logger.info("Processor logging #{events.size} events")
    events.each do |e|
      log_event(e)
    end
  end
  
  def log_event(an_event)
    @project ||= @repository.project
    event = @project.events.create!(
      :action => an_event.event_type, 
      :target => @repository, 
      :email => an_event.email,
      :body => an_event.message,
      :data => an_event.identifier,
      :created_at => an_event.commit_time
      )
    if commits = an_event.commits
      commits.each do |c|
        commit_event = event.build_commit({
          :user => c.user,
          :email => c.email,
          :body => c.message,
          :data => c.identifier
        })
        commit_event.save!
      end
    end
  end
  
  # Sets the commit summary, as served from git
  def commit_summary=(spec)
    @oldrev, @newrev, revname = spec.split(' ')
    r, name, @identifier = revname.split("/", 3)
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
    attr_accessor :event_type, :identifier, :email, :message, :commit_time, :user
    attr_reader :commits
    def to_s
      "<PushEventProcessor:EventForLogging type: #{event_type} by #{email} at #{commit_time} with #{identifier}>"
    end
    
    def commits=(commits)
      @commits = commits
    end
  end
  
  def fetch_events
    if tag?
      e = EventForLogging.new
      e.event_type = action == :create ? Action::CREATE_TAG : Action::DELETE_TAG
      e.identifier = @identifier
      rev, message = action == :create ? [@newrev, "Created tag #{@identifier}"] : [@oldrev, "Deleted branch #{@identifier}"]
      logger.debug("Processor: action is #{action}, identifier is #{@identifier}, rev is #{rev}")
      fetch_commit_details(e, rev)
      e.message = message
      return [e]
    elsif action == :create
      e = EventForLogging.new
      e.event_type = Action::CREATE_BRANCH
      e.message = "New branch"
      e.identifier = @identifier
      e.email = user.email
      result = [e]
      if @identifier == 'master'
        result = result + events_from_git_log(@newrev) 
      end
      return result
    elsif action == :delete
      e = EventForLogging.new
      e.event_type = Action::DELETE_BRANCH
      e.identifier = @identifier
      fetch_commit_details(e, @oldrev)
      return [e]
    else
      e = EventForLogging.new
      e.event_type = Action::PUSH
      e.message = "#{@identifier} changed from #{@oldrev[0,7]} to #{@newrev[0,7]}"
      e.identifier = @identifier
      e.email = user.email
      e.commits = events_from_git_log("#{@oldrev}..#{@newrev}")
      return [e]
    end
  end
    
  def fetch_commit_details(an_event, commit_sha)
    sha, email, timestamp, message = git.show({:pretty => git_pretty_format, :s => true}, commit_sha).split(PUSH_EVENT_GIT_OUTPUT_SEPARATOR_ESCAPED)
    an_event.email        = email
    an_event.commit_time  = Time.at(timestamp.to_i).utc
    an_event.message      = message
  end
  
  def events_from_git_log(revspec)
    result = []
    Grit::Git.with_timeout(nil) do
      commits = git.log({:pretty => git_pretty_format, :s => true}, revspec).split("\n")
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
    end
    return result
  end
  
  def git
    @git ||= @repository.git.git
  end
  
  def git_pretty_format
    fmt = ['%H','%cn <%ce>','%at','%s'].join(PUSH_EVENT_GIT_OUTPUT_SEPARATOR)
    "format:#{fmt}"
  end
end