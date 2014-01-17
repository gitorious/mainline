class GroupCommitterships
  def initialize(group)
    @group = group
  end

  def project_ids
    group.committerships.map{|p| p.repository.project_id }
  end

  private

  attr_reader :group
end
