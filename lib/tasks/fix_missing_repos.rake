desc "Fixes repositories which are ready, but don't exist on disk"
task :fix_missing_repos => :environment do
  Repository.where(:ready => true).includes(:project).find_each do |r|
    next if File.directory?(RepositoryRoot.expand(r.real_gitdir))

    puts "Fixing repository: #{r.project.to_param}/#{r.to_param}"
    Gitorious::App.publish("/queue/GitoriousProjectRepositoryCreation", :id => r.id)
  end
end
