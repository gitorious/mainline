class PushEventProcessor < ApplicationProcessor

  subscribes_to :push_event
  attr_reader :oldrev, :newrev, :revname
  
  def on_message(message)
    hash = ActiveSupport::JSON.decode(message)
    logger.debug("Processor on message #{hash.inspect}")
    if @repository = Repository.find_by_hashed_path(hash['gitdir'])
      self.commit_summary = hash['message']
      event = extract_event(@repository, hash['message'])
      logger.debug("Processor found repository #{@repository.id}, email: #{committer_email}")
    else
      logger.debug("Processor received message, but couldn't find repo with hashed_path #{hash['gitdir']}")
    end
  end
  
  def git
    @git ||= @repository.git.git
  end
  
  def commit_summary=(a_line)
    @oldrev, @newrev, @revname = a_line.split(' ')
  end
  
  def revision
    @revision ||= case event_type
    when Action::DELETE_BRANCH
      @oldrev
    else
      @newrev
    end
  end

  def committer_email
    result = [git.show({:pretty => 'format:%ce', :s => true}, revision)]
    return result
  end
  
  def committer
    logger.debug("Processor looking for user with email: '#{committer_email}'")
    User.find_by_email(committer_email)
  end
  
  def event_type
    if oldrev =~ /^0+$/
      action = Action::CREATE_BRANCH
    else
      if newrev =~ /^0+$/
        action = Action::DELETE_BRANCH
      else
        action = Action::COMMIT
      end
    end
    return action
  end
  
  protected
  def extract_event(a_repo, message)
    project = Project.find_by_slug('bar')
    begin 
      project.create_event(Action::COMMIT, a_repo, committer, revision, 'Unknown', Time.now)
    rescue
      logger.error("Processor got error #{$!}")
    end
  end
end