Factory.define(:membership) do |m|
  m.role_id Role::KIND_MEMBER
  m.association :user, :factory => :user
end