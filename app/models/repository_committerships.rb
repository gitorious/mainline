class RepositoryCommitterships
  def initialize(repository)
    @repository = repository
  end

  def find(id)
    repository.committerships.find(id)
  end

  def new_committership
   repository.committerships.new
  end

  def crate_for_owner!
    repository.committerships.create_for_owner!(repository.owner)
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

  private

  attr_reader :repository
end
