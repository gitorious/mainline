require "grit"

Grit.logger = Rails.logger

class Grit::Ref
  def ==(other)
    name == other.name && commit == other.commit
  end
end

class Grit::Commit
  include Comparable

  def <=>(other)
    sha <=> other.sha
  end

  def merge?
    parents.length > 1
  end
end

class Grit::Blob
  def binary?
    data[0..1024].include?("\000")
  rescue Grit::Git::GitTimeout
    # assuming binary for large blobs might be a tad too clever...
    return true
  end
end
