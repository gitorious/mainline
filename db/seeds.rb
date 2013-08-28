unless Role.count > 0
  Role.create!(:name => Role::ADMIN, :kind => Role::KIND_ADMIN)
  Role.create!(:name => Role::MEMBER, :kind => Role::KIND_MEMBER)
end
