desc "Creates missing wiki repositories"
task :fix_missing_wiki_repos => :environment do
  repo_project_ids = Repository.where(:kind => Repository::KIND_WIKI).pluck(:project_id)
  project_ids = Project.pluck(:id)
  projects_with_missing_wiki = project_ids - repo_project_ids

  puts "Attempting to fix #{projects_with_missing_wiki.count} projects without wiki repo"

  Project.where(:id => projects_with_missing_wiki).each do |project|
    command = CreateWikiRepositoryCommand.new(Gitorious::App)
    repository = command.build(project)
    command.execute(repository)
  end
end
