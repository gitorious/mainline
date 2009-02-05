class PushEventProcessor < ApplicationProcessor

  subscribes_to :push_event

  def on_message(message)
    hash = ActiveSupport::JSON.decode(message)
    logger.debug("Processor on message #{hash.inspect}")
    if repository = Repository.find_by_hashed_path(hash['gitdir'])
      logger.debug("Processor found repository #{repository}")
    else
      logger.debug("Processor received message, but couldn't find repo with hashed_path #{hash['gitdir']}")
    end
    
    # if repository = Repository.find_by_path(gitdir)
    #   logger.debug("Processor got event for #{repository}")
    # end
    
    # #    project.create_event(action_id, repository, user, ref, hash[:message], hash[:date])
    #     @publisher.post_message(JSON.unparse(hash.merge(:action => action_id, :ref => ref, :gitdir => gitdir)))

    # message_hash = ActiveSupport::JSON.decode(message)
    # target_class  = message_hash['target_class']
    # arguments     = message_hash['arguments']
    # logger.info("Processor deleting Git repository #{arguments.inspect}")
    # Repository.delete_git_repository(*arguments)
  end
end