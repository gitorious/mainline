class RepositoryCreationProcessor < ApplicationProcessor
  subscribes_to :create_repo

  def on_message(message)
    message_hash = ActiveSupport::JSON.decode(message)
    target_class  = message_hash['target_class']
    target_id     = message_hash['target_id']
    command       = message_hash['command']
    arguments     = message_hash['arguments']

    logger.info("Processor: #{target_class}(#{target_id.inspect})::#{command}(#{arguments.inspect}..)")
    target_class.constantize.send(command, *arguments)
    unless target_id.blank?
      obj = target_class.constantize.find_by_id(target_id)
      if obj && obj.respond_to?(:ready)
        obj.ready = true
        obj.save!
      end
    end
  end
end