desc 'Removes committerships with missing committer users'
task :fix_dangling_committerships do
  [User, Group].each do |owner|
    table_name = owner.table_name.to_sym

    committerships = Committership.unscoped.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = committerships.committer_id").
      where(:committer_type => owner.name, table_name => { :id => nil })

    puts "[fix_dangling_committerships] removing #{committerships.count} orphaned committerships"

    committerships.each do |committership|
      begin
        committership.destroy
      rescue => e
        committership.delete
      end
    end
  end
end
