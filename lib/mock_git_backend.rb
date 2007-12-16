class MockGitBackend
  class << self
    def create(repos_path)
      true
    end
    
    def delete!(repos_path)
      true
    end
    
    def repository_has_commits?(repos_path)
      false
    end
  end
end