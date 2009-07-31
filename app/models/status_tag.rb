class StatusTag
  def initialize(name, project)
    @name = name
    @project = project
  end
  attr_reader :name, :project

  def to_s
    name
  end

  def status
    project.merge_request_statuses.find(:first,
      :conditions => ["LOWER(name) = ?", name.downcase])
  end

  def description
    status ? status.description : nil
  end

  def color
    if status && !status.color.blank?
      status.color
    else
      "#cccccc"
    end
  end

  def open?
    return false unless status
    status.open?
  end

  def closed?
    return false unless status
    status.closed?
  end

  def unknown_state?
    status ? false : true
  end
end
