desc "Remove favorites pointing to non-existing records"
task :fix_dangling_favorites => :environment do
  watchables = [Repository, MergeRequest, Project]

  watchables.each do |type|
    table_name = type.table_name.to_sym
    favorites = Favorite.joins("left outer join #{table_name} on #{table_name}.id = favorites.watchable_id")
                        .where(:watchable_type => type.name, table_name => { :id => nil})

    puts "Removing #{favorites.count} dangling favorites for #{type.name}"
    favorites.each(&:delete)
  end
end
