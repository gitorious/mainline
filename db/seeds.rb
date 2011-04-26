unless Role.count > 0
  Role.create!(:name => "Administrator", :kind => Role::KIND_ADMIN)
  Role.create!(:name => "Committer", :kind => Role::KIND_MEMBER)
end

