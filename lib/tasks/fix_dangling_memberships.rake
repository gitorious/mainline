desc "Delete membership records pointing to non-existing users"
task :fix_dangling_memberships => :environment do
  memberships = Membership.joins("left outer join users on memberships.user_id = users.id").where(:users => { :id => nil})
  puts "Removing #{memberships.count} invalid memberships"
  memberships.each(&:destroy)
end
