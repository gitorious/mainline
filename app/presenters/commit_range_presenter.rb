class CommitRangePresenter
  include Enumerable

  attr_reader :commits
  private :commits

  attr_reader :left, :right

  def self.build(left, right, repository = nil)
    new(
      CommitPresenter.build(repository, left),
      repository.git.commits_between(left, right).map { |commit|
        CommitPresenter.build(repository, commit)
      }
    )
  end

  def initialize(left, commits)
    @left    = left
    @commits = commits
  end

  def each(&block)
    commits.each(&block)
  end

  def last
    commits.last
  end
  alias_method :right, :last
end
