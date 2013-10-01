module Gitorious
  module RepoHeader
    def repo_header(repository, opts = {})
      partial("repositories/repo_header", {
        :repository => repository,
        :project => repository.project,
        :app => Gitorious
      }.merge(opts))
    end
  end
end
