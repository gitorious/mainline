class ApplicationProcessor < ActiveMessaging::Processor
  
  def ActiveMessaging.logger
    @@logger = Logger.new(File.join(RAILS_ROOT, "log", "message_processing.log"))
  end
  
  # Default on_error implementation - logs standard errors but keeps processing. Other exceptions are raised.
  # Have on_error throw ActiveMessaging::AbortMessageException when you want a message to be aborted/rolled back,
  # meaning that it can and should be retried (idempotency matters here).
  # Retry logic varies by broker - see individual adapter code and docs for how it will be treated
  def on_error(err, message_body)
    if (err.kind_of?(StandardError))
      logger.error "Processor::on_error for msg: #{message_body}: \n" + 
      " #{err.class.name}: " + err.message + "\n" + \
      "\t" + err.backtrace.join("\n\t")
    else
      logger.error "Processor::on_error: #{err.class.name} raised: " + err.message
      raise err
    end
  end

end