desc 'Removes projects with missing owners'
task :fix_dangling_projects do
  [User, Group].each do |owner|
    table_name = owner.table_name.to_sym

    projects = Project.unscoped.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = projects.owner_id").
      where(:owner_type => owner.name, table_name => { :id => nil })

    Rails.logger.debug "[fix_dangling_projects] removing #{projects.count} orphaned projects"

    projects.each do |project|
      begin
        project.destroy
      rescue => e
        project.delete
      end
    end
  end
end
