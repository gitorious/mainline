desc 'Removes repositories with missing projects'
task :fix_dangling_repositories do
  [User, Project].each do |model|
    table_name = model.table_name.to_sym
    name       = model.name

    repositories = Repository.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = repositories.#{name.underscore}_id").
      where(table_name => { :id => nil })

    puts "[fix_dangling_repositories] removing #{repositories.count} orphaned repositories"

    repositories.each do |repository|
      begin
        repository.destroy
      rescue => e
        repository.delete
      end
    end
  end

  [User, Group].each do |model|
    table_name = model.table_name.to_sym
    name       = model.name

    repositories = Repository.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = repositories.owner_id").
      where(:owner_type => name, table_name => { :id => nil })

    puts "[fix_dangling_repositories] removing #{repositories.count} orphaned repositories"

    repositories.each do |repository|
      begin
        repository.destroy
      rescue => e
        repository.delete
      end
    end
  end
end
