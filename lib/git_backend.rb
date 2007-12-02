class GitBackend
  class << self
    def create(repos_path)
      FileUtils.mkdir(repos_path, :mode => 0750)
      Dir.chdir(repos_path) do |path| 
        Git.init(path, :repository => path)
      end
    end
    
    def repository_has_commits?(repos_path)
      Dir[File.join(repos_path, "refs/heads/*")].size > 0
    end
  end
end