class RepositoryCommitterships
  def initialize(repository)
    @repository = repository
  end

  def find(id)
    committerships.find(id)
  end

  def new_committership
    Committership.new(repository: repository)
  end

  def create_for_owner!(another_owner = owner, creator = nil)
    committerships.create_for_owner!(another_owner, creator)
  end

  def destroy_for_owner
    existing = committerships.find_by_committer_id_and_committer_type(owner.id, owner.class.name)
    existing.destroy if existing
  end

  def update_owner(another_owner, creator = nil)
    if cs_to_upgrade = committerships.detect{|c|c.committer == another_owner}
      cs_to_upgrade.build_permissions(:review, :commit, :admin)
      cs_to_upgrade.save!
    else
      create_for_owner!(another_owner, creator)
    end
  end

  def destroy(id, current_user)
    committership = find(id)

    # Update creator to hold the "destroyer" user account
    # Makes sure hooked-in event reports correct destroying user
    # We have no other way of passing destroying user along
    # except restructing code to not use implicit event hooks.
    committership.creator = current_user
    committership.destroy
  end

  def committerships
    repository.committerships
  end

  def committers
    committerships.committers.map{|c| c.members }.flatten.compact.uniq
  end

  def reviewers
    committerships.reviewers.map{|c| c.members }.flatten.compact.uniq
  end

  def administrators
    committerships.admins.map{|c| c.members }.flatten.compact.uniq
  end

  def admins
    committerships.select { |c| c.admin? }
  end

  def members
    committerships.
      includes(:committer).
      map(&:committer).
      flat_map { |committer| committer.is_a?(User) ? committer : committer.members }.
      uniq
  end

  def users
    committerships.users
  end

  def groups
    committerships.groups
  end

  private

  attr_reader :repository

  def owner
    repository.owner
  end
end

