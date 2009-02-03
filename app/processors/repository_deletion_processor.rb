class RepositoryDeletionProcessor < ApplicationProcessor

  subscribes_to :destroy_repo

  def on_message(message)
    message_hash = ActiveSupport::JSON.decode(message)
    target_class  = message_hash['target_class']
    arguments     = message_hash['arguments']
    logger.info("Deleting Git repository #{arguments.inspect}")
    Repository.delete_git_repository(*arguments)
  end
end