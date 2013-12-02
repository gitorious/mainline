module SendMessage
  def self.call(opts)
    Message.create!(opts)
  end
end
