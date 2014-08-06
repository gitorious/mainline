class RepositoryPolicy

  attr_reader :user, :repository, :db_authorization

  def self.allowed?(user, repository, action)
    action = "#{action.to_s.gsub('-', '_')}?"
    new(user, repository).public_send(action)
  end

  def initialize(user, repository, db_authorization = Gitorious::Authorization::DatabaseAuthorization.new)
    @user = user
    @repository = repository
    @db_authorization = db_authorization
  end

  def read?
    db_authorization.can_read_repository?(user, repository)
  end

  alias_method :upload_pack?, :read?

  def receive_pack?
    false
  end

end
