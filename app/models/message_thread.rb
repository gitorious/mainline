class MessageThread
  attr_reader :recipients, :sender
  include Enumerable

  def initialize(options)
    @subject    = options[:subject]
    @body       = options[:body]
    @sender     = options[:sender]
    @recipients = extract_recipients(options[:recipients])
    RAILS_DEFAULT_LOGGER.debug("MessageThread for #{@recipients.join(',')}")
  end
  
  def each
    messages.each{|m| yield m}
  end
  
  def extract_recipients(recipient_string)
    recipient_string.split(/[,\s\.]/).map(&:strip)    
  end
  
  def messages
    @messages ||= initialize_messages
  end
  
  def size
    messages.size
  end
  
  def title
    "#{size} " + ((size == 1) ? 'message' : 'messages')
  end
  
  # Returns a message object, used in views etc
  def message
    Message.new(:sender => @sender, :subject => @subject, :body => @body)
  end
  
  def save
    all_ok = nil
    messages.each{|msg|
      all_ok = true if all_ok.nil?
      all_ok = false unless msg.save
    }
    return all_ok
  end
  
  protected
    def initialize_messages
      recipients.inject([]) do |result, recipient_name|
        result << Message.new(:sender => @sender, :subject => @subject, :body => @body, :recipient => User.find_by_login(recipient_name))
      end
    end
end