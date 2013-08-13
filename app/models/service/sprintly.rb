class Service::Sprintly < Service::Adapter
  def self.multiple?
    false
  end

  def to_s
    "Sprint.ly Product: #{id}"
  end
end
